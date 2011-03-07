module Data.Rewriting.Term.Type (
    Term (..),
    fold,
    map,
) where

import Prelude hiding (map)

data Term f v
    = Var v            -- ^ Variable
    | Fun f [Term f v] -- ^ Function application
    deriving (Show, Eq, Ord)

-- | Folding terms.
--
-- >>> fold (\v -> 1) (\f xs -> 1 + sum xs) (Fun 'f' [Var 1, Fun 'g' []])
-- 3 -- size of the given term
fold :: (v -> a) -> (f -> [a] -> a) -> Term f v -> a
fold var fun (Var v) = var v
fold var fun (Fun f ts) = fun f (fmap (fold var fun) ts)

-- | Mapping terms: Rename function symbols and variables.
--
-- >>> map succ pred (Fun 'f' [Var 2, Fun 'g' []])
-- Fun 'e' [Var 3,Fun 'f' []]
map :: (v -> v') -> (f -> f') -> Term f v -> Term f' v'
map var fun = fold (Var . var) (Fun . fun)

