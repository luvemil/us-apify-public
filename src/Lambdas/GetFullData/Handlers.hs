module Lambdas.GetFullData.Handlers where

import Amazonka
import Amazonka.S3
import ApiClient.Loader (loadConfigText)
import ApiClient.Types
import Control.Lens
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Except
import Crawl.PClient qualified as PClient
import Crawl.PClient.Feed
import Data.Aeson qualified as Aeson
import Data.Text qualified as T
import Data.Text.Encoding qualified as T
import Lambdas.GetFullData.Actions
import Polysemy
import Polysemy.Error
import Polysemy.Error qualified as PE
import Polysemy.Input
import Polysemy.State
import Polysemy.Storage
import System.Environment (getEnv)
import Utils.AWS

handler :: String -> IO (Either String ())
handler profileName = do
    ac <- loadApiConfigFromS3
    (region, tableName) <- loadDynamoDBTarget
    handleGetFullData
        ac
        (runDataStorage profileName region tableName)
        profileName

handleGetFullData ::
    ApiConfig ->
    (forall r a. Members '[PE.Error String, State (Maybe PClient.ProfileID), Embed IO] r => Sem (Storage [DataDetail] ': r) a -> Sem r a) ->
    String ->
    IO (Either String ())
handleGetFullData ac runStorage profileName = do
    res <-
        getFullData profileName
            & runFeedToPClientState
            & runStorage
            & stateToIO @(Maybe PClient.ProfileID) Nothing
            & runInputConst pClientFeedConfig
            & PClient.runPClientToIO
            & runInputConst ac
            & runError @String
            & runM
    case res of
        Left s -> pure $ Left s
        Right _ -> pure $ Right ()

loadApiConfigFromS3 :: IO ApiConfig
loadApiConfigFromS3 = do
    (region, bucket, objKey) <- loadApiConfigS3Target
    loadApiConfig region bucket objKey

loadApiConfig :: Region -> BucketName -> ObjectKey -> IO ApiConfig
loadApiConfig region bucket objKey = do
    content <- getFile region bucket objKey
    case loadConfigText (T.decodeUtf8 content) of
        Left s -> fail s
        Right x -> pure x

loadApiConfigS3Target :: IO (Region, BucketName, ObjectKey)
loadApiConfigS3Target = do
    region <- fromEnv "API_CONFIG_S3_REGION"
    bucket <- fromEnv "API_CONFIG_S3_BUCKET"
    objKey <- fromEnv "API_CONFIG_S3_OBJECT_KEY"
    pure (region, bucket, objKey)

loadDynamoDBTarget :: IO (Region, T.Text)
loadDynamoDBTarget = do
    table <- getEnv "DYNAMO_DB_TABLE_NAME"
    region <- fromEnv "DYNAMO_DB_REGION"
    pure (region, T.pack table)

runDataStorage :: forall r a. Members '[PE.Error String, State (Maybe PClient.ProfileID), Embed IO] r => String -> Region -> T.Text -> Sem (Storage [DataDetail] ': r) a -> Sem r a
runDataStorage profileName region tableName sem =
    let -- fn :: Member (Storage [Value]) r => [DataDetail] -> Sem r [Aeson.Value]
        -- TODO: edit to use profileName and profileId
        fn posts = do
            profileId <- get @(Maybe PClient.ProfileID)
            pure $ toOutput profileId profileName posts
     in sem
            & runStorageToStorageH fn
            & runAesonStorageToDynamoDB region tableName

runAesonStorageToDynamoDB :: Members '[PE.Error String, Embed IO] r => Aeson.ToJSON v => Region -> T.Text -> Sem (Storage v ': r) a -> Sem r a
runAesonStorageToDynamoDB region tableName = runStorageToIO fn
  where
    fn v = runExceptT $ do
        items <- buildPutItemsObjectList tableName v
        liftIO $ saveToDynamoDB region items
