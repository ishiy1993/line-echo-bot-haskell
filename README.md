# LINE Echo Bot in Haskell
LINE BOT CARAVANのときに作ったEcho Botです。

scottyとwreqを使用しています。

注意:

+ ~~LINEサーバーからのsignatureの検証をしていません~~ => 検証するようにしました
+ ~~text以外のメッセージが来たときの挙動を確認していません~~ => typeによってテキトーに返答メッセージを変えるようにしました
