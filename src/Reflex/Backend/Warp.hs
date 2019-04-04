{-|
Copyright   : (c) Dave Laing, 2017-2019
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable

Serving reflex networks using @warp@.

-}

{-# language FlexibleContexts, TypeFamilies #-}
{-# language RankNTypes #-}
module Reflex.Backend.Warp where

import Reflex hiding (Request, Response)
import Reflex.Host.Basic (BasicGuestConstraints, BasicGuest, basicHostForever)
import Reflex.Backend.Wai

import Control.Concurrent (forkIO)
import Control.Monad (void)
import Network.Wai (Request, Response)
import Network.Wai.Handler.Warp (Port, run)

-- | Serve a reflex network using warp.
runAppForever
  :: Port -- ^ Server port
  -> (forall t m.
      BasicGuestConstraints t m =>
      Event t Request ->
      BasicGuest t m (Event t Response)) -- ^ Reflex network
  -> IO ()
runAppForever port network = do
  waiSource <- newWaiSource
  void . forkIO $ basicHostForever (waiApplicationGuest waiSource network)
  void . run port $ waiApplicationHost waiSource
