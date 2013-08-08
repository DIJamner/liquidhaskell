{-# LANGUAGE BangPatterns, TupleSections #-}

import qualified Data.HashMap.Strict as M
import qualified Control.Exception as Ex
import Data.Maybe       (catMaybes)
import Data.Monoid      (mconcat)
import System.Exit 
import Control.Applicative ((<$>))
import Control.DeepSeq
import Control.Monad (forM, when)

import CoreSyn
import FastString
import GHC
import HscMain
import RdrName
import Var

import System.Console.CmdArgs.Verbosity (whenLoud)
import System.Console.CmdArgs.Default
import Language.Fixpoint.Config (Config (..)) 
import Language.Fixpoint.Files
-- import Language.Fixpoint.Names
import Language.Fixpoint.Misc
import Language.Fixpoint.Names (dropModuleNames)
import Language.Fixpoint.Interface
import Language.Fixpoint.Types (sinfo, colorResult, FixResult (..),showFix, isFalse)

import qualified Language.Haskell.Liquid.DiffCheck as DC
import Language.Haskell.Liquid.Types
import Language.Haskell.Liquid.CmdLine
import Language.Haskell.Liquid.GhcInterface
-- import Language.Haskell.Liquid.Result
import Language.Haskell.Liquid.Constraint       
import Language.Haskell.Liquid.TransformRec   
import Language.Haskell.Liquid.Annotate (annotate)

main :: IO b
main = liquid >>= (exitWith . resultExit)

liquid  = do cfg <- getOpts
             res <- forM (files cfg) $ \t ->
                      Ex.catch (liquidOne cfg t) $ \e -> 
                      do let err = show (e :: Ex.IOException)
                         putStrLn $ "Unexpected Error: " ++ err
                         return $ Crash [] "Whoops! Unknown Failure"
             return $ mconcat res

liquidOne cfg target = 
  do _        <- getFixpointPath 
     info     <- getGhcInfo cfg target 
     whenLoud  $ do donePhase Loud "getGhcInfo"
                    putStrLn $ showpp info 
                    putStrLn "*************** Original CoreBinds ***************************" 
                    putStrLn $ showpp (cbs info)
     let cbs' = transformRecExpr (cbs info)
     whenLoud  $ do donePhase Loud "transformRecExpr"
                    putStrLn "*************** Transform Rec Expr CoreBinds *****************" 
                    putStrLn $ showpp cbs'
                    putStrLn "*************** Slicing Out Unchanged CoreBinds *****************" 
     (pruned, cbs'') <- prune cfg cbs' target info
     let cgi = {-# SCC "generateConstraints" #-} generateConstraints cfg $! info {cbs = cbs''}
     cgi `deepseq` donePhase Loud "generateConstraints"
     -- whenLoud $ do donePhase Loud "START: Write CGI (can be slow!)"
     --                {-# SCC "writeCGI" #-} writeCGI target cgi 
     --                donePhase Loud "FINISH: Write CGI"
     (r, sol) <- solveCs cfg target cgi info
     _        <- when (diffcheck cfg) $ DC.save target 
     donePhase Loud "solve"
     let out   = Just $ O (checkedNames pruned cbs'') (logWarn cgi) sol (annotMap cgi)
     exitWithResult target (sinfo <$> r) out 

checkedNames False _    = Nothing
checkedNames True cbs   = Just $ concatMap names cbs
  where
    names (NonRec v _ ) = [varName v]
    names (Rec bs)      = map (varName . fst) bs

prune cfg cbs target info
  | not (null vs) = return (True, DC.thin cbs vs)
  | diffcheck cfg = (True,) <$> DC.slice target cbs
  | otherwise     = return (False, cbs)
  where 
    vs            = tgtVars $ spec info

solveCs cfg target cgi info 
  | nofalse cfg
  = do  hqBot <- getHqBotPath
        (_, solBot) <- solve fx target [hqBot] (cgInfoFInfoBot cgi)
        let falseKvars = M.keys (M.filterWithKey (const isFalse) solBot)
        putStrLn $ "False KVars" ++ show falseKvars
        solve fx target (hqFiles info) (cgInfoFInfoKvars cgi falseKvars)
  
  | otherwise
  = solve fx target (hqFiles info) (cgInfoFInfo cgi)
  where 
    fx = def { solver = smtsolver cfg }

writeCGI tgt cgi = {-# SCC "ConsWrite" #-} writeFile (extFileName Cgi tgt) str
  where 
    str          = {-# SCC "PPcgi" #-} showFix cgi
 
