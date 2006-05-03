
module TypeChecking.Substitute where

import Control.Monad.Identity
import Control.Monad.Reader
import Data.Generics

import Syntax.Internal
import Syntax.Internal.Walk

-- | This can never be right! Isn't this going to add the arguments everywhere,
--   not just at top-level?
addArgs :: Args -> GenericT
addArgs args = mkT addTrm `extT` addTyp where
    addTrm m = case m of
        Var i args' -> Var i (args'++args)
        Lam m args' -> Lam m (args'++args)
        Def c args' -> Def c (args'++args)
        MetaV x args' -> MetaV x (args'++args) 
	_	      -> m
    addTyp a = case a of
        MetaT x args' -> MetaT x (args'++args)
	_	      -> a

-- | Also wrong?
abstract :: [Value] -> GenericT
abstract args = mkT absV `extT` absT where
    absV v = foldl (\v _ -> Lam  (Abs "x" v) []) v args
    absT a = foldl (\a _ -> LamT (Abs "x" a)   ) a args 

-- | Substitute @repl@ for @(Var 0 _)@ in @x@.
--
subst :: Value -> GenericT
subst repl x = runIdentity $ walk (mkM goVal) x where
  goVal (Var i args) = do
      n <- ask
      if i == n 
          then do 
              args' <- mapM goVal args
              endWalk $ addArgs args' $ adjust n repl 
          else return $ Var (if i > n then i - 1 else i) args
  goVal x = return x

-- | Add @k@ to index of each open variable in @x@.
--
adjust :: Int -> GenericT
adjust k x = runIdentity $ walk (mkM goTm) x where
  goTm (Var i args) = do
      n <- ask
      return $ Var (if i >= n then i + k else i) args
  goTm x = return x

