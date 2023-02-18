module Lambdas.GetFullData.ActionsSpec where

import Control.Lens
import Crawl.PClient.Actions qualified as PClient
import Crawl.PClient.Effect qualified as PClient
import Crawl.PClient.Feed
import Crawl.PClient.Types
import Data.Aeson
import Data.ByteString.Lazy.Char8 qualified as BSL
import Data.Either (isRight)
import Data.Map qualified as M
import GHC.IO (unsafePerformIO)
import Lambdas.GetFullData.Actions
import Polysemy
import Polysemy.Error
import Polysemy.Fail
import Polysemy.Input
import Polysemy.Output
import Polysemy.State
import Polysemy.Storage
import Test.Hspec

main :: IO ()
main = hspec spec

testProfile :: String
{-# NOINLINE testProfile #-}
testProfile = unsafePerformIO $ readFile "data/test_profile.html"

testPosts :: Response
{-# NOINLINE testPosts #-}
testPosts = unsafePerformIO $ do
    s <- BSL.readFile "data/test_posts_003.json"
    case eitherDecode' s of
        Right x -> pure x
        Left y -> fail y

testProfileMap :: M.Map String String
testProfileMap = M.singleton "fakeName" testProfile

testPostsMap :: M.Map ProfileID Response
testPostsMap = M.singleton (ProfileID 123456789) testPosts

spec :: Spec
{-# NOINLINE spec #-}
spec = do
    describe "getFullData" $ do
        it "raises an error if the profile name doesn't exist" $ do
            let action = getFullData "doesn't exist"
            p <-
                action
                    & runFeedToPClientState
                    & stateToIO Nothing
                    & runInputConst pClientFeedConfig
                    & runStorageToOutput
                    & ignoreOutput
                    & PClient.runPClientConstMap testProfileMap testPostsMap
                    & runError
                    & runM
            p `shouldBe` (Left "ProfileNotFound")
        it "sets the correct profile in the state" $ do
            let action = getFullData "fakeName"
            p <-
                action
                    & runFeedToPClientState
                    & stateToIO Nothing
                    & runInputConst pClientFeedConfig
                    & runStorageToOutput
                    & ignoreOutput
                    & PClient.runPClientConstMap testProfileMap testPostsMap
                    & runError
                    & runM
            -- p `shouldBe` (Right ([testPosts], (Just (ProfileID 123456789), ())))
            p `shouldBe` Right (Just (ProfileID 123456789), ())
        it "reads the correct number of posts" $ do
            let action = getFullData "fakeName"
            p <-
                action
                    & runFeedToPClientState
                    & stateToIO Nothing
                    & runInputConst pClientFeedConfig
                    & runStorageToOutput
                    & runOutputList
                    & PClient.runPClientConstMap testProfileMap testPostsMap
                    & runError
                    & runM
            -- p `shouldBe` (Right ([testPosts], (Just (ProfileID 123456789), ())))
            let l = case p of
                    Left s -> Left s
                    Right ([], _) -> Left $ "0 Items found"
                    Right ([posts], _) -> Right $ length posts
                    Right (xs, _) -> Left $ "Too many outputs"
            l `shouldBe` Right 5