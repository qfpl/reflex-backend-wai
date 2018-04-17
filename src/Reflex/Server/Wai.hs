{-# LANGUAGE FlexibleContexts #-}
module Reflex.Server.Wai where

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

data WaiSource =
  WaiSource {
    wsRequest :: TMVar Request
  , wsResponse :: TMVar Response
  }

newWaiSource ::
  STM WaiSource
newWaiSource =
  WaiSource <$> newEmptyTMVar <*> newEmptyTMVar

waiApplicationHost ::
  WaiSource ->
  Application
waiApplicationHost (WaiSource wReq wRes) req response = do
  atomically $ putTMVar wReq req
  res <- atomically $ takeTMVar wRes
  response res

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

pumpWaiApplication ::
  Application ->
  Request ->
  IO Response
pumpWaiApplication app req = do
  v <- atomically newEmptyTMVar
  _ <- app req $ \res -> do
    atomically . putTMVar v $ res
    pure ResponseReceived
  atomically $ takeTMVar v

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

  let
    go res = do
      onRes res
      pure ResponseReceived
  performEvent_ $ (\req -> void . liftIO $ app req go) <$> eReq

  pure eRes

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

  let
    go t res = do
      onRes (Map.singleton t res)
      pure ResponseReceived
  performEvent_ $ (\(t, req) -> void . liftIO . app req $ go t) <$> eReq

  pure eRes
