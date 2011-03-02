module Data.Rewriting.Substitution.Match (
    match,
) where

import Data.Rewriting.Substitution.Type
import qualified Data.Rewriting.Term.Type as Term
import Data.Rewriting.Term.Type (Term (..))

import qualified Data.Map as M
import Control.Monad
import Control.Applicative

match :: (Eq f, Ord v, Eq v') => Term f v -> Term f v' -> Maybe (GSubst v f v')
match t u = fromMap <$> go t u (M.empty) where
   go (Var v) t subst = case M.lookup v subst of
       Nothing -> Just (M.insert v t subst)
       Just t' | t == t' -> Just subst
       _ -> Nothing
   go (Fun f ts) (Fun f' ts') subst
       | f /= f' || length ts /= length ts' = Nothing
       | otherwise = composeM (zipWith go ts ts') subst
   go _ _ _ = Nothing

-- TODO: move to Utils module
composeM :: Monad m => [a -> m a] -> a -> m a
composeM = foldr (>=>) return
