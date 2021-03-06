-- This file is part of the 'term-rewriting' library. It is licensed
-- under an MIT license. See the accompanying 'LICENSE' file for details.
--
-- Authors: Martin Avanzini, Manuel Schneckenreither

module Data.Rewriting.Typed.Problem.Pretty (
    prettyProblem,
    prettyWST,
    prettyWST',
) where

import           Data.List                         (nub)
import           Data.Maybe                        (fromJust, isJust)
import           Data.Rewriting.Typed.Datatype     (prettyDatatype)
import           Data.Rewriting.Typed.Problem.Type
import           Data.Rewriting.Typed.Rule         (prettyRule)
import           Data.Rewriting.Typed.Signature    (prettySignature)
import           Text.PrettyPrint.ANSI.Leijen


printWhen' :: Bool -> Doc -> (Doc -> Doc)
printWhen' False _ = (empty <>)
printWhen' True  p = (p <$$> )
infixr 5 `printWhen'`

printWhen :: Bool -> Doc -> Doc
printWhen False _ = empty
printWhen True  p = p


prettyWST' :: (Pretty f, Pretty v, Pretty s, Pretty sDt, Pretty dt, Pretty cn) =>
             Problem f v s sDt dt cn -> Doc
prettyWST' = prettyWST pretty pretty pretty pretty pretty pretty

prettyWST :: (f -> Doc) -> (v -> Doc) -> (s -> Doc) -> (sDt -> Doc) -> (dt -> Doc) -> (cn -> Doc)
          -> Problem f v s sDt dt cn -> Doc
prettyWST fun var sign sDt dt ctr prob =
    printWhen' (sterms /= AllTerms) (block "STARTTERM" $ text "CONSTRUCTOR-BASED")
    $ printWhen' (strat /= Full) (block "STRATEGY" $ ppStrat strat)
    $ maybeblock "THEORY" theory ppTheories
    <$$> block "VAR" (ppVars $ variables prob)
    <$$> maybeblock "DATATYPES" datatypes ppDatatypes
    <$$> maybeblock "SIGNATURES" signatures ppSigs
    <$$> block "RULES" (ppRules $ rules prob)
    <$$> maybeblock "COMMENT" comment text

  where block n pp = parens $ hang 3 $ text n <$$> pp
        maybeblock n f fpp = case f prob of
                               Just e  -> block n (fpp e)
                               Nothing -> empty

        ppStrat Innermost = text "INNERMOST"
        ppStrat Outermost = text "OUTERMOST"

        ppVars vs = align $ fillSep [ var v | v <- vs]

        ppTheories thys = align $ vcat [ppThy thy | thy <- thys]
            where ppThy (SymbolProperty p fs) = block p (align $ fillSep [ fun f | f <- fs ])
                  ppThy (Equations rs)        = block "EQUATIONS" $ vcat [ppRule "==" r | r <- rs]

        ppRules rp = align $ vcat ([ppRule "->" r | r <- strictRules rp]
                                   ++ [ppRule "->=" r | r <- weakRules rp])

        ppRule sep = prettyRule (text sep) fun var

        ppDatatypes dts = align $ vcat [ ppDatatype "=" dt | dt <- dts ]
        ppDatatype sep = prettyDatatype (text sep) dt ctr

        ppSigs sigs        = align $ vcat $ [ppSig "::"  "->" sig | sig <- sigs ]
        ppSig sep0 sep1    = prettySignature (text sep0) (text sep1) sign sDt


        sterms = startTerms prob
        strat  = strategy prob
        thry   = theory prob


prettyProblem :: (Eq f, Eq v, Eq s, Eq sDt, Eq dt, Eq cn) => (f -> Doc) -> (v -> Doc) -> (s -> Doc) ->
                (sDt -> Doc) -> (dt -> Doc) -> (cn -> Doc) -> Problem f v s sDt dt cn -> Doc
prettyProblem fun var sign sDt dt cn prob =  block "Start-Terms" (ppST `on` startTerms)
                                                 <$$> block "Strategy" (ppStrat `on` strategy)
                                                 <$$> block "Variables" (ppVars `on` variables)
                                                 <$$> maybeblock "Data-Types" ppDts datatypes
                                                 <$$> maybeblock "Signatures" ppSigs signatures
                                                 <$$> block "Function Symbols" (ppSyms `on` symbols)
                                                 <$$> maybeblock "Theory" ppTheories theory
                                                 <$$> block "Rules" (ppRules `on` rules)
                                                 <$$> maybeblock "Comment" ppComment comment where
  pp `on` fld = pp $ fld prob
  block n pp = hang 3 $ underline (text $ n ++ ":") <+> pp
  maybeblock n pp f = -- printWhen (isJust `on` f)
    (block n (pp `on` (fromJust . f)))
  commalist  = fillSep . punctuate (text ",")


  ppST AllTerms   = text "all"
  ppST BasicTerms = text "basic terms"
  ppStrat Innermost = text "innermost"
  ppStrat Outermost = text "outermost"
  ppStrat Full      = text "full rewriting"
  ppVars vars        = commalist [var v | v <- nub vars]
  ppSyms syms        = commalist [fun v | v <- nub syms]
  ppComment          = text
  ppTheories ths     =  align $ vcat [ ppTheory th | th <- ths ] where
      ppTheory (SymbolProperty p fs) = text (p++":") <+> align (commalist [ fun f | f <- fs])
      ppTheory (Equations rs)        = align $ vcat [ppRule "==" r | r <- rs]
  ppRules rp         = align $ vcat $
                       [ppRule "->" r | r <- strictRules rp]
                       ++ [ppRule "->=" r | r <- weakRules rp]
  ppRule sep'        = prettyRule (text sep') fun var
  ppDts dts          = align $ vcat [ppDt "=" dt' | dt' <- dts]
  ppDt sep'          = prettyDatatype (text sep') dt cn
  ppSigs sigs        = align $ vcat [ppSig "::" "->" sig | sig <- sigs ]
  ppSig sep0 sep1    = prettySignature (text sep0) (text sep1) sign sDt

instance (Eq f, Eq v, Eq s, Eq sDt, Eq dt, Eq cn, Pretty f, Pretty v, Pretty s, Pretty sDt,
          Pretty dt, Pretty cn) => Pretty (Problem f v s sDt dt cn) where
  pretty = prettyProblem pretty pretty pretty pretty pretty pretty
