{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.IO.Class (liftIO)
import Control.Monad (when)
import Control.Lens ((^.),(^?), (?~), (&), ix)
import Data.Aeson (object, (.=))
import Data.Aeson.Lens (key, _Array, _Object, _String)
import Data.ByteString.Base64.Lazy (encode)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Lens (packedChars)
import Data.Digest.Pure.SHA (hmacSha256, bytestringDigest)
import Data.Text.Lazy (Text)
import Data.Text.Lazy.Encoding (decodeUtf8)
import Network.Wreq (postWith, responseStatus, defaults, auth, oauth2Bearer)
import System.Environment (getEnv)
import Web.Scotty (scotty, post, body, header)

main :: IO ()
main = do
    accessToken <- (^. packedChars) <$> getEnv "Line_Access_Token"
    secretToken <- (^. packedChars) <$> getEnv "Line_Secret_Token"
    scotty 4567 $
        post "/callback" $ do
            Just sig <- header "X-Line-Signature"
            b <- body
            when (check sig secretToken b) $ do
                liftIO $ print b
                let Just ev = b ^? key "events" . _Array . ix 0 . _Object
                let token = ev ^. ix "replyToken" . _String
                    m = case ev ^. ix "type" . _String of
                          "message" -> ev ^. ix "message" . _Object . ix "text" . _String
                          "beacon" -> "Beacon!!"
                          _ -> "Others"
                    msg = object ["type" .= ("text" :: String), "text" .= m]
                    res = object ["replyToken" .= token, "messages" .= [msg]]
                    opt = defaults & auth ?~ oauth2Bearer accessToken
                liftIO $ print res
                r <- liftIO $ postWith opt lineUrl res
                liftIO $ print $ r ^. responseStatus

lineUrl :: String
lineUrl = "https://api.line.me/v2/bot/message/reply"

check :: Text -> ByteString -> ByteString -> Bool
check sig secret b = sig == sig'
    where
        sig' = decodeUtf8 . encode . bytestringDigest $ hmacSha256 secret b
