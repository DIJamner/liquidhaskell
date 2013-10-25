{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- ---------------------------------------------------------------------------
-- |
-- Module      : Data.Vector.Algorithms.Common
-- Copyright   : (c) 2008-2011 Dan Doel
-- Maintainer  : Dan Doel
-- Stability   : Experimental
-- Portability : Portable
--
-- Common operations and utility functions for all sorts

module Data.Vector.Algorithms.Common where

import Language.Haskell.Liquid.Prelude (liquidAssert)

import Prelude hiding (read, length)

import Control.Monad.Primitive

import Data.Vector.Generic.Mutable

import qualified Data.Vector.Primitive.Mutable as PV

----------------------------------------------------------------------------
-- LIQUID Specifications ---------------------------------------------------
----------------------------------------------------------------------------

-- | Vector Size Measure

{-@ measure vsize :: a -> Int @-}

-- | Vector Type Aliases
{-@ type      BNat  N     = {v:Nat | v < N}         @-}
{-@ type      OkIdx X     = {v:Nat | v < (vsize X)} @-}
{-@ predicate OkOff V B O = (vsize V) <= B + O      @-}
{-@ predicate EqSiz X Y   = (vsize X) = (vsize Y)   @-}

-- | Assumed Types for Vector

{-@ Data.Vector.Generic.Mutable.length      
      :: (Data.Vector.Generic.Mutable.MVector v a) 
      => x:(v s a) 
      -> {v:Nat | v = (vsize x)} 
  @-}

{-@ Data.Vector.Generic.Mutable.unsafeRead  
      :: (PrimMonad m, Data.Vector.Generic.Mutable.MVector v a) 
      => x:(v (PrimState m) a) 
      -> (OkIdx x) 
      -> m a       
  @-}

{-@ Data.Vector.Generic.Mutable.unsafeWrite 
      :: (PrimMonad m, Data.Vector.Generic.Mutable.MVector v a) 
      => x:(v (PrimState m) a) 
      -> (OkIdx x) 
      -> a 
      -> m () 
  @-}

{-@ unsafeSlice 
      :: Data.Vector.Generic.Mutable.MVector v a 
      => i:Nat 
      -> n:Nat 
      -> {v:(v s a) | (OkOff v i n)} 
      -> {v:(v s a) | (vsize v) = n}  
  @-}

{-@ Data.Vector.Generic.Mutable.unsafeCopy  
      :: (PrimMonad m, Data.Vector.Generic.Mutable.MVector v a) 
      => src:(v (PrimState m) a) 
      -> {dst:(v (PrimState m) a) | (EqSiz src dst)} 
      -> m () 
  @-}

{-@ qualif OkIdx(v:a, x:b): v <= (vsize x)        @-}
{-@ qualif OkIdx(v:a, x:b): v <  (vsize x)        @-}
{-@ qualif EqSiz(x:a, y:b): (vsize x) = (vsize y) @-}
{-@ qualif Plus(v:Int, x:Int, y:Int): v + x = y   @-}
----------------------------------------------------------------------------

-- | A type of comparisons between two values of a given type.
type Comparison e = e -> e -> Ordering

{-@ copyOffset :: (PrimMonad m, MVector v e)
               => from  : (v (PrimState m) e) 
               -> to    : (v (PrimState m) e) 
               -> iFrom : Nat 
               -> iTo   : Nat 
               -> {len  : Nat | ((OkOff from iFrom len) && (OkOff to iTo len))} 
               -> m ()
  @-}
copyOffset :: (PrimMonad m, MVector v e)
           => v (PrimState m) e -> v (PrimState m) e -> Int -> Int -> Int -> m ()
copyOffset from to iFrom iTo len =
  unsafeCopy (unsafeSlice iTo (len + 1) to) (unsafeSlice iFrom len from)
{-# INLINE copyOffset #-}

{-@ inc :: (PrimMonad m, MVector v Int) => x:(v (PrimState m) Int) -> (OkIdx x) -> m Int @-}
inc :: (PrimMonad m, MVector v Int) => v (PrimState m) Int -> Int -> m Int
inc arr i = unsafeRead arr i >>= \e -> unsafeWrite arr i (e+1) >> return e
{-# INLINE inc #-}


-- LIQUID: flipping order to allow dependency.
-- shared bucket sorting stuff
{-@ countLoop :: (PrimMonad m, MVector v e)
              => (v (PrimState m) e) 
              -> count:(PV.MVector (PrimState m) Int) 
              -> (e -> (OkIdx count)) ->  m ()
  @-}
countLoop :: (PrimMonad m, MVector v e)
          => (v (PrimState m) e) -> (PV.MVector (PrimState m) Int) 
          -> (e -> Int) ->  m ()
countLoop src count rdx = set count 0 >> go len 0
 where
 len = length src
 go (m :: Int) i
   | i < len   = let lenSrc = length src 
                      
                 in (liquidAssert (i < lenSrc) $ unsafeRead src i) >>= inc count . rdx >> go (m-1) (i+1)
   | otherwise = return ()
{-# INLINE countLoop #-}























