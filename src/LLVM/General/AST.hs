-- | This modules defines AST data types to represent LLVM code
module LLVM.General.AST (
  Module(..), defaultModule,
  Definition(..),
  Global(GlobalVariable, GlobalAlias, Function), 
        globalVariableDefaults,
        globalAliasDefaults,
        functionDefaults,
  Parameter(..),
  BasicBlock(..),
  module LLVM.General.AST.Instruction,
  module LLVM.General.AST.Name,
  module LLVM.General.AST.Operand,
  module LLVM.General.AST.Type
  ) where

import LLVM.General.AST.Name
import LLVM.General.AST.Type
import LLVM.General.AST.Global
import LLVM.General.AST.Operand
import LLVM.General.AST.Instruction
import LLVM.General.AST.DataLayout

data Definition 
  = GlobalDefinition Global
  | TypeDefinition Name (Maybe Type)
  | MetadataNodeDefinition MetadataNodeID [Operand]
  | NamedMetadataDefinition String [MetadataNodeID]
  | ModuleInlineAssembly String
    deriving (Eq, Read, Show)

-- | <http://llvm.org/docs/LangRef.html#modulestructure>
data Module = 
  Module {
    moduleName :: String,
    moduleDataLayout :: Maybe DataLayout,
    moduleTargetTriple :: Maybe String,
    moduleDefinitions :: [Definition]
  } 
  deriving (Eq, Read, Show)

defaultModule = 
  Module {
    moduleName = "<string>",
    moduleDataLayout = Nothing,
    moduleTargetTriple = Nothing,
    moduleDefinitions = []
  }
