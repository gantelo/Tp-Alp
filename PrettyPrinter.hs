module PrettyPrinter where

import Eval
import Common
import Failable

import Text.PrettyPrint.HughesPJ

--------------------------------------------------------------------------------

-- Pretty Printer para resultado de evaluación
pp :: Failable Env -> Doc
pp (Ok env) = ppEnv env
pp (Error err) = text err

-- Pretty Printer para entorno
ppEnv :: Env -> Doc
ppEnv [] = text "Entorno Vacío"
ppEnv env =  let docs = map ppEnvItem env
                 docs2 = punctuate (text "\n") docs
             in hcat docs2


-- Pretty Printer para elemento de entorno
ppEnvItem :: EnvItem -> Doc
ppEnvItem (var, item) = text (var ++ " :=  ") Text.PrettyPrint.HughesPJ.<> ppVarType item

-- Pretty Printer para contenido de variable evaluada
ppVarType :: VarType -> Doc
ppVarType (VarList a) = ppIntList a
ppVarType (VarFunc a) = ppRLFunc a



-- Pretty Printer de listas
ppLists :: Lists -> Doc
ppLists (L l) = ppIntList l
ppLists (Cat l1 l2) =   ppLists l1 Text.PrettyPrint.HughesPJ.<>
                        text " + " Text.PrettyPrint.HughesPJ.<>
                        ppLists l2
ppLists (LVar var) = ppVar var

-- Pretty Printer de variables (etiqueta)
ppVar :: String -> Doc
ppVar s = text "var" Text.PrettyPrint.HughesPJ.<>
          parens (text s)

-- Pretty Printer de lista de enteros
ppIntList :: [Int] -> Doc
ppIntList list = ppGenList int (text ", ") (text "[") (text "]") list

-- Pretty Printer de tipo de variable (definición)
ppVT :: VT -> Doc
ppVT VTFunc = text "func"
ppVT VTList = text "list"

-- Pretty Printer de Funciones Recursivas de Lista
ppRLFunc :: RLFunc -> Doc
ppRLFunc Ol = text "0l"
ppRLFunc Or = text "0r"
ppRLFunc Rl = text "Rl"
ppRLFunc Rr = text "Rr"
ppRLFunc Sl = text "Sl"
ppRLFunc Sr = text "Sr"
ppRLFunc (Rep f) =  (text "< ") Text.PrettyPrint.HughesPJ.<>
                    (ppRLFunc f) Text.PrettyPrint.HughesPJ.<>
                    (text " >")
ppRLFunc (FVar var) = ppVar var
ppRLFunc c@(Comp _ _) = ppGenList ppRLFunc (text " ") (text "{ ") (text " }") (compFuncToList c)
ppRLFunc None = text "{}"




-- Pretty Printer de valores (antes de ser evaluados)
ppValue :: Value -> Doc
ppValue (Func f) = ppRLFunc f
ppValue (List l) = ppLists l
ppValue (Apply f l) =   ppRLFunc f Text.PrettyPrint.HughesPJ.<>
                        text " " Text.PrettyPrint.HughesPJ.<>
                        ppLists l

-- Pretty Printer de comandos
ppComm :: Comm -> Doc
ppComm (VarDef var vt value) =  text "let " Text.PrettyPrint.HughesPJ.<>
                                text (var ++ ": ") Text.PrettyPrint.HughesPJ.<>
                                (ppVT vt) Text.PrettyPrint.HughesPJ.<>
                                text " = " Text.PrettyPrint.HughesPJ.<>
                                ppValue value
ppComm (Assign var val) =   text var Text.PrettyPrint.HughesPJ.<>
                            text " = " Text.PrettyPrint.HughesPJ.<>
                            ppValue val
ppComm (Seq c1 c2) = ppComm c1 Text.PrettyPrint.HughesPJ.<>
                     text "\n" Text.PrettyPrint.HughesPJ.<>
                     ppComm c2


--------------------------------------------------------------------------------
-- Funciones auxiliares


-- convierte items en doc, separador, init tok, end tok
ppGenList :: (a -> Doc) -> Doc -> Doc -> Doc -> [a] -> Doc
ppGenList f sep ini end list = ini Text.PrettyPrint.HughesPJ.<> ppGenList' list Text.PrettyPrint.HughesPJ.<> end
                                 where   ppGenList' [] = empty
                                         ppGenList' [a] = f a
                                         ppGenList' (a: l@(b:xs)) = f a Text.PrettyPrint.HughesPJ.<> sep Text.PrettyPrint.HughesPJ.<> ppGenList' l

-- Convierte una cimposición de funciones en una lista
-- En caso de no ser una composición no hace nada
compFuncToList :: RLFunc -> [RLFunc]
compFuncToList (Comp f1 f2) =   let l1 = case f1 of
                                         None -> []
                                         _ -> compFuncToList f1
                                    l2 = case f2 of
                                             None -> []
                                             _ -> compFuncToList f2
                                 in l1 ++ l2
compFuncToList a = [a]