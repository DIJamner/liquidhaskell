module Test0 where

import Language.Haskell.Liquid.Prelude
-- import MyPrelude

x = choose 0

prop_abs ::  Bool
prop_abs = if x > 0 then baz x else False


baz gooberding = assert (gooberding >= 0)
