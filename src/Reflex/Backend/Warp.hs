{-# language FlexibleContexts, TypeFamilies #-}
{-# language RankNTypes #-}
module Reflex.Backend.Warp where

import Reflex hiding (Request, Response)
import Reflex.Host.Basic (BasicGuestConstraints, BasicGuest, basicHostForever)
import Reflex.Backend.Wai

import Control.Concurrent (forkIO)
import Control.Monad (void)
import Control.Monad.STM (atomically)
import Network.Wai (Request, Response)
import Network.Wai.Handler.Warp (Port, run)

runAppForever
  :: Port
  -> (forall t m.
      BasicGuestConstraints t m =>
      Event t Request ->
      BasicGuest t m (Event t Response))
  -> IO ()
runAppForever port network = do
  waiSource <- atomically newWaiSource
  void . forkIO $ basicHostForever (waiApplicationGuest waiSource network)
  void . run port $ waiApplicationHost waiSource