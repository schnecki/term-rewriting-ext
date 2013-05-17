module Data.Rewriting.Term.Ops (
    -- * Operations on Terms
    funs,
    funsDL,
    vars,
    varsDL,
    withArity,
    subtermAt,
    -- * Predicates on Terms
    isVar,
    isFun,
    isGround,
    isLinear,
    isInstanceOf,
    isVariantOf,
) where

import Data.Rewriting.Pos
import Data.Rewriting.Term.Type as Term
import Data.Rewriting.Substitution.Match
import Data.Maybe
import qualified Data.MultiSet as MS


-- | Annotate each occurrence of a function symbol with its actual arity,
-- i.e., its number of arguments.
--
-- >>> withArity (Fun 'f' [Var 1, Fun 'f' []])
-- Fun ('f',2) [Var 1,Fun ('f',0) []]
withArity :: Term f v -> Term (f, Int) v
withArity = Term.fold Var (\f ts -> Fun (f, length ts) ts)

-- | Return the subterm at a given position.
subtermAt :: Term f v -> Pos -> Maybe (Term f v)
subtermAt t [] = Just t
subtermAt (Fun _ ts) (p:ps) | p >= 0 && p < length ts = subtermAt (ts !! p) ps
subtermAt _ _ = Nothing

-- | Return the list of all variables in the term, from left to right.
--
-- >>> vars (Fun 'g' [Var 3, Fun 'f' [Var 1, Var 2, Var 3]])
-- [3,1,2,3]
vars :: Term f v -> [v]
vars = flip varsDL []

-- | Difference List version of 'vars'.
-- We have @varsDL t vs = vars t ++ vs@.

varsDL :: Term f v -> [v] -> [v]
varsDL = Term.fold (:) (const $ foldr (.) id)

-- | Return the list of all function symbols in the term, from left to right.
--
-- >>> funs (Fun 'f' [Var 3, Fun 'g' [Fun 'f' []]])
-- "fgf"
funs :: Term f v -> [f]
funs = flip funsDL []

-- | Difference List version of 'funs'.
-- We have @funsDL t vs = funs t ++ vs@.

funsDL :: Term f v -> [f] -> [f]
funsDL = Term.fold (const id) (\f xs -> (f:) . foldr (.) id xs)

-- | Return 'True' if the term is a variable, 'False' otherwise.
isVar :: Term f v -> Bool
isVar Var{} = True
isVar Fun{} = False

-- | Return 'True' if the term is a function application, 'False' otherwise.
isFun :: Term f v -> Bool
isFun Var{} = False
isFun Fun{} = True

-- | Check whether the term is a ground term, i.e., contains no variables.
isGround :: Term f v -> Bool
isGround = null . vars

-- | Check whether the term is linear, i.e., contains each variable at most
-- once.
isLinear :: Ord v => Term f v -> Bool
isLinear = all (\(_, c) -> c == 1) . MS.toOccurList . MS.fromList . vars

-- | Check whether a term is an instance of another.
isInstanceOf :: (Eq f, Ord v, Ord v') => Term f v -> Term f v' -> Bool
isInstanceOf t u = isJust (match u t)

-- | Check whether a term is a variant of another.
isVariantOf :: (Eq f, Ord v, Ord v') => Term f v -> Term f v' -> Bool
isVariantOf t u = isInstanceOf t u && isInstanceOf u t
