module Main where

import Aws.Lambda
import Lib qualified as Lib

main :: IO ()
main =
  runLambdaHaskellRuntime
    defaultDispatcherOptions
    (pure ())
    id
    (addStandaloneLambdaHandler "handler" Lib.handler)