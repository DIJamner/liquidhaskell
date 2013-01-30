{-@ predicate NonNull X = ((len X) > 0) @-}

-- THIS WORKS
{- risers :: (Ord a) => zs:{v: [a] | (len v) >= 0 } -> {v: [[a]] | ((NonNull zs) => (NonNull v)) } @-} 

-- THIS DOESNT, ADD invariant to spec-types
{-@ risers :: (Ord a) => zs:[a] -> {v: [[a]] | ((NonNull zs) => (NonNull v)) } @-} 
risers []        
  = []
risers [x]       
  = [[x]]
risers (x:y:etc) 
  = if x <= y then (x:s):ss else [x]:(s:ss)
    where (s, ss) = safeSnoc $ risers (y:etc)

{-@ safeSnoc     :: {v : [a] | (NonNull v) } -> (a, [a]) @-}
safeSnoc (x:xs)  = (x, xs)
safeSnoc _       = error "WHOOPS!"
