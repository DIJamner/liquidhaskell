{-# LANGUAGE ScopedTypeVariables #-}
{-@ LIQUID "--no-termination" @-}

module Class () where

import Language.Haskell.Liquid.Prelude
import Prelude hiding (sum, length, (!!), Functor(..))
import qualified Prelude as P

{-@ qualif Size(v:int, xs:a): v = (sz xs) @-}

{-@ data List a = Nil | Cons (hd::a) (tl::(List a)) @-}
data List a = Nil | Cons a (List a)

{-@ length :: xs:List a -> {v:Nat | v = (sz xs)} @-}
length :: List a -> Int
length Nil         = 0
length (Cons x xs) = 1 + length xs

{-@ (!!) :: xs:List a -> {v:Nat | v < (sz xs)} -> a @-}
(!!) :: List a -> Int -> a
Nil         !! i = undefined
(Cons x _)  !! 0 = x
(Cons x xs) !! i = xs !! (i - 1)

{-@ class measure sz :: forall a. a -> Int @-}


class Sized s where
  size :: s a -> Int
  emp  :: s a -> Bool
  emp  = (0 ==) . size 

instance Sized List where
  size = length

instance Sized [] where
  size [] = 0
  size (x:xs) = 1 + size xs

{-@ class Sized s where
      size :: forall a. x:s a -> {v:Nat | v = (sz x)}
      emp  :: forall a. s a -> Bool
  @-}

{-@ instance measure sz :: List a -> Int
    sz (Nil)       = 0
    sz (Cons x xs) = 1 + (sz xs)
  @-}

{-@ instance measure sz :: [a] -> Int
      sz ([])   = 0
      sz (x:xs) = 1 + (sz xs)
  @-}


{-@ class (Sized s) => Indexable s where
      index :: forall a. x:s a -> {v:Nat | v < (sz x)} -> a
  @-}
class (Sized s) => Indexable s where
  index :: s a -> Int -> a


instance Indexable List where
  index = (!!)

{-@ sum :: Indexable s => s Int -> Int @-}
sum :: Indexable s => s Int -> Int
sum xs = go n 0
  where
    n = size xs
    go (d::Int) i
      | i < n = index xs i + go (d-1) (i+1)
      | otherwise = 0


{-@ sumList :: List Int -> Int @-}
sumList :: List Int -> Int
sumList xs = go n 0
  where
    n = size xs
    go (d::Int) i
      | i < n = index xs i + go (d-1) (i+1)
      | otherwise = 0


{-@ x :: {v:List Int | (sz v) = 3}  @-}
x :: List Int
x = 1 `Cons` (2 `Cons` (3 `Cons` Nil))

foo = liquidAssert $ size (Cons 1 Nil) == size [1]
