module Lambdas.GetFullData.Actions where

import Crawl.Feed qualified as Feed
import Crawl.PClient qualified as PClient
import Crawl.PClient.Feed qualified as PClient
import Polysemy
import Polysemy.Error
import Polysemy.Input
import Polysemy.State
import Polysemy.Storage

getFullData ::
    Members
        '[ PClient.PClient
         , Error String
         , State (Maybe PClient.ProfileID)
         , Feed.Feed PClient.Response PClient.DataSummary PClient.DataDetail
         , Input (Feed.FeedConfig PClient.Response PClient.DataSummary PClient.DataDetail)
         , Storage [PClient.DataDetail]
         ]
        r =>
    String ->
    Sem r ()
getFullData profileName = do
    pId <- fromEither =<< PClient.getProfileId profileName
    put $ Just pId
    res <- Feed.downloadFullProfile @PClient.Response @PClient.DataSummary @PClient.DataDetail
    saveData res