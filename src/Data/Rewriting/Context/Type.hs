module Data.Rewriting.Context.Type (
    Ctxt (..),
) where

import Data.Rewriting.Term (Term(..))

data Ctxt f v
    = Hole                                    -- ^ Hole
    | Ctxt f [Term f v] (Ctxt f v) [Term f v] -- ^ Non-empty context

    -- CS: would it make sense to reverse the left term list?
    deriving (Show, Eq, Ord)
