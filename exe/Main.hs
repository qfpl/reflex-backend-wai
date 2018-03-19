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

import Control.Monad.STM

import Network.Wai
import Network.Wai.Handler.Warp (run)

import Network.HTTP.Types.Status

import Reflex.Host.Basic
import Reflex.Server.Wai

guest :: WaiSource -> IO ()
guest ws = basicHostForever $ waiApplicationGuest ws $ \eReq -> do
  let
    eRes = responseLBS status200 [] "Hi" <$ eReq
  pure eRes

main :: IO ()
main = do
  waiSource <- atomically newWaiSource
  guest waiSource
  run 8080 $ waiApplicationHost waiSource
  pure ()
