module Lambdas.Types where

import Data.Aeson

data LRequest = GetFullData String
    deriving (Show, Eq)

instance FromJSON LRequest where
    parseJSON = withObject "LRequest" $ \o -> do
        typeS :: String <- o .: "type"
        case typeS of
            "SAVE" -> GetFullData <$> o .: "payload"
            _ -> fail "Unexpected request"