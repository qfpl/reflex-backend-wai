# reflex-backend-wai

`reflex` support for WAI applications

## Example

This example implements a reflex network that responds "Hi" to 
every request:

```
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.Wai (responseLBS)
import Network.HTTP.Types.Status (status200)

import Reflex.Backend.Warp (runAppForever)

main :: IO ()
main =
  runAppForever 8080 $ \eReq -> do
    let eRes = responseLBS status200 [] "Hi" <$ eReq
    pure eRes
```

## Contribution

Feel free to file an issue or pull request on Github, or contact us at:

* IRC - #qfpl on Freenode
* Email - <oᴉ˙ldɟb@llǝʞsɐɥ>

