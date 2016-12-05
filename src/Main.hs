{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.IO.Class
import Control.Lens
import Data.Aeson
import Data.Aeson.Lens
import GHC.Exts (fromList)
import GHC.Generics
import qualified Network.Wreq as W
import Web.Scotty

main :: IO ()
main = scotty 4567 $
    post "/callback" $ do
        b <- body
        liftIO $ print b
        let Just ev = b ^? key "events" . _Array . ix 0 . _Object
        let token = ev ^. ix "replyToken" . _String
            m = ev ^. ix "message" . _Object . ix "text" . _String
            msg = Object $ fromList [("type", String "text")
                                    ,("text", String m)]
            res = Object $ fromList [("replyToken", String token)
                                    ,("messages", Array $ fromList [msg])]
            opt = W.defaults & W.auth ?~ W.oauth2Bearer accessToken
        liftIO $ print res
        r <- liftIO $ W.postWith opt lineUrl res
        liftIO $ print $ r ^. W.responseStatus

lineUrl :: String
lineUrl = "https://api.line.me/v2/bot/message/reply"

accessToken = "Your Channel Access Token"
