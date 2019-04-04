{-|
Copyright   : (c) Dave Laing, 2017-2019
License     : BSD3
Maintainer  : dave.laing.80@gmail.com
Stability   : experimental
Portability : non-portable

Low level operations for integrating reflex networks with WAI
'Application's.

If you just want to serve a reflex network then have a look
at "Reflex.Backend.Warp".

-}

{-# LANGUAGE FlexibleContexts #-}
module Reflex.Backend.Wai
  ( WaiSource(..), newWaiSource
  , waiApplicationGuest
  , waiApplicationHost
  , liftWaiApplication, liftWaiApplicationTagged
  )
where

import Network.Wai
import Network.Wai.Internal (ResponseReceived(..))

import Control.Monad (void, forever)

import Control.Monad.Trans (MonadIO, liftIO)

import Data.Map (Map)
import qualified Data.Map as Map

import Control.Concurrent (forkIO)
import Control.Monad.STM
import Control.Concurrent.STM

import Reflex hiding (Request, Response)

-- | The source of the WAI application data.
--
-- Requests generated by the web server are stored here, and read
-- by the reflex network.
--
-- Responses generated by the reflex network are stored here, and
-- read (and subsequently returned) by the web server.
data WaiSource
  = WaiSource
  { wsRequest :: TMVar Request
  , wsResponse :: TMVar Response
  }

-- | Initialise a 'WaiSource'
newWaiSource :: MonadIO m => m WaiSource
newWaiSource =
  liftIO $ WaiSource <$> newEmptyTMVarIO <*> newEmptyTMVarIO

-- | Build an 'Application' that deposits a 'Request' into the
-- 'WaiSource', then reads a 'Response' from the 'WaiSource', then
-- responds with it.
waiApplicationHost :: WaiSource -> Application
waiApplicationHost (WaiSource wReq wRes) req response = do
  atomically $ putTMVar wReq req
  res <- atomically $ takeTMVar wRes
  response res

-- | Build a reflex network that pumps 'Request's and 'Response's to
-- and from the 'WaiSource'
waiApplicationGuest ::
  ( Reflex t
  , MonadIO m
  , PerformEvent t m
  , MonadIO (Performable m)
  , TriggerEvent t m
  ) =>
  WaiSource ->
  (Event t Request -> m (Event t Response)) ->
  m ()
waiApplicationGuest (WaiSource wReq wRes) network = do
  (eReq, onReq) <- newTriggerEvent
  eRes <- network eReq

  performEvent_ $ liftIO . atomically . putTMVar wRes <$> eRes

  void . liftIO . forkIO . forever $ do
    req <- atomically $ takeTMVar wReq
    onReq req

  pure ()

-- | Given a WAI 'Application' and a 'Request' event, create an
-- 'Event' that yield a 'Response' by running the 'Application'.
--
-- The output 'Event' will fire some time after the input 'Event'.
liftWaiApplication ::
  ( Reflex t
  , PerformEvent t m
  , MonadIO (Performable m)
  , TriggerEvent t m
  ) =>
  Application ->
  Event t Request ->
  m (Event t Response)
liftWaiApplication app eReq = do
  (eRes, onRes) <- newTriggerEvent

  let go res = ResponseReceived <$ onRes res

  performEvent_ $ (\req -> void . liftIO $ app req go) <$> eReq

  pure eRes

-- | Similar to 'liftWaiApplication', but the 'Request' event should yield
-- a tag which is then attached to the 'Response'.
liftWaiApplicationTagged ::
  ( Reflex t
  , PerformEvent t m
  , MonadIO (Performable m)
  , TriggerEvent t m
  ) =>
  Application ->
  Event t (tag, Request) ->
  m (Event t (Map tag Response))
liftWaiApplicationTagged app eReq = do
  (eRes, onRes) <- newTriggerEvent

  let go t res = ResponseReceived <$ onRes (Map.singleton t res)

  performEvent_ $ (\(t, req) -> void . liftIO . app req $ go t) <$> eReq

  pure eRes
