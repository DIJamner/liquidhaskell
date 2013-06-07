module spec Prelude where

import GHC.Base
import GHC.List
import Data.Maybe
assume GHC.Base..               :: forall< p :: xx:b -> c -> Prop
                                         , q :: yy:a -> b -> Prop>.
                                      f:(x:b -> c<p x>) -> 
                                      g:(y:a -> b<q y>) -> 
                                      x:a -> 
                                      exists[z:b<q x>].c<p z>
assume GHC.Integer.smallInteger :: x:GHC.Prim.Int# -> {v: Prelude.Integer | v = (x :: Prelude.Integer)}
assume GHC.Num.+                :: (Prelude.Num a) => x:a -> y:a -> {v:a | v = x + y }
assume GHC.Num.-                :: (Num a) => x:a -> y:a -> {v:a | v = x - y }
assume GHC.Num.*                :: (Num a) => x:a -> y:a -> {v:a | (((x >= 0) && (y >= 0)) => (v >= 0)) }
assume GHC.Real.div             :: (Integral a) => x:a -> y:a -> {v:a | v = (x / y) }
assume GHC.Real.mod             :: (Integral a) => x:a -> y:a -> {v:a | v = (x mod y) }
assume GHC.Real./               :: (Fractional a) => x:a -> y:{v:a | v != 0} -> {v: a | v = (x / y) }
assume GHC.Num.fromInteger      :: (Num a) => x:Prelude.Integer -> {v:a | v = x }
assume GHC.Real.toInteger       :: (Integral a) => x:a -> {v:Prelude.Integer | v = x}
assume GHC.Real.fromIntegral    :: (Integral a, Num b) => x:a -> {v:b|v=x}

-- assume GHC.Real.fromIntegral    :: (Integral a, Num b) => x: a -> {v: b | ((x != 0) => (v != 0))}



embed Prelude.Integer  as int

type GeInt N = {v: GHC.Types.Int | v >= N }

type Nat     = {v: GHC.Types.Int | (v >= 0)}

