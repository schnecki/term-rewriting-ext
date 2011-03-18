module Data.Rewriting.Rule.Ops (
    isLinear, isLeftLinear, isRightLinear,
    isGround, isLeftGround, isRightGround,
    isErasing,
    isCreating,
    isDuplicating,
    isCollapsing,
    isValid,
    funsDL
) where

import Data.Rewriting.Rule.Type
import qualified Data.Rewriting.Term as Term

import qualified Data.Set as S
import qualified Data.MultiSet as MS

-- | Test whether the given predicate is true for both sides of a rule.
both :: (Term f v -> Bool) -> Rule f v -> Bool
both p r = p (lhs r) && p (rhs r)

-- | Apply a function to the lhs of a rule.
left :: (Term f v -> a) -> Rule f v -> a
left f = f . lhs

-- | Apply a function to the rhs of a rule.
right :: (Term f v -> a) -> Rule f v -> a
right f = f . rhs

-- hmm, many similar variants. is this justified for rules and TRSs?

isLinear :: Ord v => Rule f v -> Bool
isLinear = both Term.isLinear

isLeftLinear :: Ord v => Rule f v -> Bool
isLeftLinear = left Term.isLinear

isRightLinear :: Ord v => Rule f v -> Bool
isRightLinear = right Term.isLinear

isGround :: Rule f v -> Bool
isGround = both Term.isGround

isLeftGround :: Rule f v -> Bool
isLeftGround = left Term.isGround

isRightGround :: Rule f v -> Bool
isRightGround = right Term.isGround

varsS :: Ord v => Term f v -> S.Set v
varsS = S.fromList . Term.vars

isErasing :: Ord v => Rule f v -> Bool
isErasing r = not $ varsS (lhs r) `S.isSubsetOf` varsS (rhs r)

isCreating :: Ord v => Rule f v -> Bool
isCreating r = not $ varsS (rhs r) `S.isSubsetOf` varsS (lhs r)

varsMS :: Ord v => Term f v -> MS.MultiSet v
varsMS = MS.fromList . Term.vars

isDuplicating :: Ord v => Rule f v -> Bool
isDuplicating r = not $ varsMS (rhs r) `MS.isSubsetOf` varsMS (lhs r)

isCollapsing :: Rule f v -> Bool
isCollapsing = Term.isVar . lhs

isExpanding :: Rule f v -> Bool
isExpanding = Term.isVar . rhs

-- | Check whether rule is non-erasing and non-expanding.
isValid :: Ord v => Rule f v -> Bool -- MA: keep?
isValid r = not (isErasing r) && not (isExpanding r)

funsDL ::  Rule f v -> [f] -> [f]
funsDL r = Term.funsDL (lhs r) . Term.funsDL (rhs r)