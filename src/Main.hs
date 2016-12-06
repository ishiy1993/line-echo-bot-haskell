{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.IO.Class
import Control.Lens ((^.),(^?), (?~), (&), ix)
import Data.Aeson
import Data.Aeson.Lens
import Data.ByteString.Lens (packedChars)
import Network.Wreq (postWith, responseStatus, defaults, auth, oauth2Bearer)
import System.Environment (getEnv)
import Web.Scotty (scotty, post, body)

main :: IO ()
main = do
    accessToken <- getEnv "Line_Access_Token"
    secretToken <- getEnv "Line_Secret_Token"
    scotty 4567 $
        post "/callback" $ do
            b <- body
            liftIO $ print b
            let Just ev = b ^? key "events" . _Array . ix 0 . _Object
            let token = ev ^. ix "replyToken" . _String
                m = ev ^. ix "message" . _Object . ix "text" . _String
                msg = object ["type" .= ("text" :: String), "text" .= m]
                res = object ["replyToken" .= token, "messages" .= [msg]]
                opt = defaults & auth ?~ oauth2Bearer (accessToken^.packedChars)
            liftIO $ print res
            r <- liftIO $ postWith opt lineUrl res
            liftIO $ print $ r ^. responseStatus

lineUrl :: String
lineUrl = "https://api.line.me/v2/bot/message/reply"
