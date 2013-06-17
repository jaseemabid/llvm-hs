module LLVM.General.Internal.ExecutionEngine where

import Control.Exception
import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.AnyCont
import Data.Functor

import Foreign.Ptr
import Foreign.Marshal.Alloc (free)

import qualified LLVM.General.Internal.FFI.PtrHierarchy as FFI
import qualified LLVM.General.Internal.FFI.ExecutionEngine as FFI
import qualified LLVM.General.Internal.FFI.Target as FFI
import qualified LLVM.General.Internal.FFI.Module as FFI

import LLVM.General.Internal.Module
import LLVM.General.Internal.Context
import LLVM.General.Internal.Coding

import qualified LLVM.General.AST as A

newtype ExecutionEngine = ExecutionEngine (Ptr FFI.ExecutionEngine)

removeModule :: Ptr FFI.ExecutionEngine -> Ptr FFI.Module -> IO ()
removeModule e m = flip runAnyContT return $ do
  d0 <- alloca
  d1 <- alloca
  r <- liftIO $ FFI.removeModule e m d0 d1
  when (r /= 0) $ fail "FFI.removeModule failure"


withExecutionEngine :: Context -> (ExecutionEngine -> IO a) -> IO a
withExecutionEngine c f = flip runAnyContT return $ do
  liftIO $ FFI.initializeNativeTarget
  outExecutionEngine <- alloca
  outErrorCStringPtr <- alloca
  Module dummyModule <- anyContT $ liftM (either undefined id) . withModuleFromAST c (A.Module "" Nothing Nothing [])
  r <- liftIO $ FFI.createExecutionEngineForModule outExecutionEngine dummyModule outErrorCStringPtr
  when (r /= 0) $ do
    s <- anyContT $ bracket (peek outErrorCStringPtr) free
    fail =<< decodeM s
  executionEngine <- anyContT $ bracket (peek outExecutionEngine) FFI.disposeExecutionEngine
  liftIO $ removeModule executionEngine dummyModule
  liftIO $ f (ExecutionEngine executionEngine)
          
      
withModuleInEngine :: ExecutionEngine -> Module -> IO a -> IO a
withModuleInEngine (ExecutionEngine e) (Module m) = bracket_ (FFI.addModule e m) (removeModule e m)

findFunction :: ExecutionEngine -> A.Name -> IO (Maybe (Ptr ()))
findFunction (ExecutionEngine e) (A.Name fName) = flip runAnyContT return $ do
  out <- alloca
  fName <- encodeM fName
  r <- liftIO $ FFI.findFunction e fName out
  if (r /= 0) then 
      return Nothing
   else 
      Just <$> (liftIO $ FFI.getPointerToGlobal e . FFI.upCast =<< peek out)
