module Lib where

import Aws.Lambda
import Lambdas.GetFullData.Handlers qualified as GFD
import Lambdas.Types

main :: IO ()
main = do
    putStrLn "Entrypoint"

handler :: LRequest -> Context () -> IO (Either String String)
handler (GetFullData profileName) _ = GFD.handler profileName >> pure (Right "OK")
