{-|
Copyright   : (c) Dave Laing, 2017
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable
-}
{-# LANGUAGE OverloadedStrings #-}
module Main (
    main
  ) where

import Network.Wai (responseLBS)
import Network.HTTP.Types.Status (status200)

import Reflex.Server.Warp (runAppForever)

main :: IO ()
main =
  runAppForever 8080 $ \eReq -> do
    let eRes = responseLBS status200 [] "Hi" <$ eReq
    pure eRes