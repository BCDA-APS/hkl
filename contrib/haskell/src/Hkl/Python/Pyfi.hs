{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}

module Hkl.Python.Pyfi (
    module X,
    defO,
    defV,
    defOO,
    defOV,
    defVO,
    defVV,
    defOOO,
    defOOV,
    defOVO,
    defOVV,
    defVOO,
    defVOV,
    defVVO,
    defVVV,
    defOOOO,
    defOOOV,
    defOOVO,
    defOOVV,
    defOVOO,
    defOVOV,
    defOVVO,
    defOVVV,
    defVOOO,
    defVOOV,
    defVOVO,
    defVOVV,
    defVVOO,
    defVVOV,
    defVVVO,
    defVVVV,
    defVVVVV,
    defVVVVO,
    PyObject,
    PythonException,
    exceptionType,
    extractNumpyArray
    , matrixToPyObject
    )
where

import Prelude hiding (lookup)
import Control.Exception (Exception, throw)
import Control.Monad ((<=<), unless, when)
import Data.Aeson (FromJSON, ToJSON, encode, eitherDecode)
import Data.Array.Repa (Array, Shape, shapeOfList)
import Data.Array.Repa.Repr.ForeignPtr (F, fromForeignPtr)
import Data.ByteString.Lazy.Char8 (unpack, pack)
import Data.Digest.Pure.MD5 (md5)
import Data.IORef (IORef, newIORef, writeIORef, readIORef)
import Data.Map (Map, empty, insert, lookup, member)
import Data.Maybe (fromJust)
import Data.Monoid (mconcat)
import Data.List (elemIndex)
import Data.Typeable (Typeable)
import Foreign (FunPtr, ForeignPtr)
import Foreign.C (CInt(..), CIntPtr(..), CString, peekCString, withCString)
import Foreign.ForeignPtr (castForeignPtr, newForeignPtr, withForeignPtr)
import Foreign.Marshal.Alloc (free, finalizerFree)
import Foreign.Marshal.Array (peekArray, withArray)
import Foreign.Ptr (Ptr, nullPtr)
import Numeric.LinearAlgebra (Matrix, flatten, toList)
import Safe.Partial (Partial)
import System.IO.Unsafe (unsafePerformIO)

import Hkl.Python.QQ as X

{-# NOINLINE modules #-}
modules :: IORef (Map String RawPyObject)
modules = unsafePerformIO $ newIORef empty

data P

type RawPyObject = (Ptr P)

newtype PyObject a = PyObject (ForeignPtr P) deriving Show

data PythonException = PyException { exceptionType :: String
                                   , exceptionValue :: String
                                   }
                     | DecodeException { exceptionValue :: String }
                       deriving (Typeable)

instance Show PythonException where
    show (DecodeException x) = "DecodeException " ++ x
    show x = exceptionType x ++ "\n" ++ exceptionValue x

instance Exception PythonException

-- foreign import ccall "getObject" c_getObject:: CString -> IO RawPyObject
foreign import ccall "getObjectInModule" c_getObjectInModule :: CString -> CString -> IO RawPyObject
foreign import ccall "execInModule" c_execInModule :: CString -> CString -> IO ()
-- foreign import ccall "PyRun_SimpleString" pyRun_SimpleString :: CString -> IO ()
-- foreign import ccall "Py_DecRef" py_DecRef :: RawPyObject -> IO ()
foreign import ccall "Py_Initialize" py_initialize :: IO ()
-- foreign import ccall "Py_Finalize" finalize :: IO ()
foreign import ccall "Py_BuildValue" py_BuildValueString :: CString -> CString -> IO RawPyObject
-- foreign import ccall "Py_BuildValue" py_BuildValueString2 :: CString -> CString -> CString -> IO RawPyObject
foreign import ccall "Py_BuildValue" py_BuildValueObject :: CString -> RawPyObject -> IO RawPyObject
foreign import ccall "Py_BuildValue" py_BuildValueObject2 :: CString -> RawPyObject -> RawPyObject -> IO RawPyObject
foreign import ccall "Py_BuildValue" py_BuildValueObject3 :: CString -> RawPyObject -> RawPyObject -> RawPyObject -> IO RawPyObject
foreign import ccall "Py_BuildValue" py_BuildValueObject4 :: CString -> RawPyObject -> RawPyObject -> RawPyObject -> RawPyObject -> IO RawPyObject
foreign import ccall "PyObject_CallObject" pyObject_CallObject :: RawPyObject -> RawPyObject -> IO RawPyObject
foreign import ccall "PyUnicode_AsUTF8" pyUnicode_AsUTF8 :: RawPyObject -> IO CString
foreign import ccall unsafe "gimmeFunc" gimmeFunc :: CInt -> IO (FunPtr (RawPyObject -> IO ()))
foreign import ccall "checkError" c_checkError :: IO CString

-- exec :: String -> IO ()
-- exec s = withCString s pyRun_SimpleString

withCString2 :: String -> String -> (CString -> CString -> IO a) -> IO a
withCString2 s1 s2 f = withCString s1 f' where
    f' cs1 = withCString s2 (f cs1)

execInModule :: String -> String -> IO ()
execInModule moduleName payload =
    withCString2 payload moduleName c_execInModule

parseException :: String -> PythonException
parseException s = let (t, v) = splitAt (fromJust (elemIndex ',' s)) s
                       (_, t2) = splitAt (fromJust (elemIndex '\'' t)) t
                       (t3, _) = splitAt (fromJust (elemIndex '\'' (tail t2 ))) (tail t2 )
                   in PyException { exceptionType = t3
                                  , exceptionValue = tail v
                                  }

checkError :: String -> IO ()
checkError funcdef = do
  cs <- c_checkError
  if cs == nullPtr
  then return ()
  else do
    s <- peekCString cs
    free cs
    throw . parseException $ mconcat[s, "\n", take 70 $ cycle "-", "\n", funcdef]

initialize :: IO ()
initialize = py_initialize

getObjectInModule :: String -> String -> IO RawPyObject
getObjectInModule moduleName objectName =
    withCString2 objectName moduleName c_getObjectInModule

-- getObject :: String -> IO RawPyObject
-- getObject s = withCString s c_getObject

jsonfunc :: String
jsonfunc = [str|
def jsonfunc(argformats):
    def wrapper(f):
        import json
        import traceback
        def json_wrapper(*args):
            try:
                new_args = []
                for (x, format) in zip(args, argformats):
                    if format == 'V':
                        new_x = json.loads(x)
                        new_args.append(new_x)
                    else:
                        new_args.append(x)
                result = f(*new_args)
                if argformats[-1] == 'V':
                    result = json.dumps(result)
                return result
            except Exception as ex:
                assert("," not in str(type(ex)))
                ex.args = (traceback.format_exc(),)
                raise ex
        return json_wrapper
    return wrapper
|]

hash :: String -> String
hash contents = show . md5 $ pack contents

mydecode :: (FromJSON a) => String -> Either String a
mydecode s = do
    x <- eitherDecode . pack . (\x -> "[" ++ x ++ "]") $ s
    return $ head x -- This code is dangerous. prelude's `head` isnt safe


toPyObject :: (ToJSON a) => a -> IO (PyObject b)
toPyObject x = do
    y <- return . unpack . encode $ x
    p <- withCString "s" $ \cs ->
         withCString y (py_BuildValueString cs)
    newForeignPyPtr p

fromPyObject :: (FromJSON a) => PyObject b -> IO a
fromPyObject (PyObject fr) = do
    r2 <- withForeignPtr fr (peekCString <=< pyUnicode_AsUTF8)
    either (throw . DecodeException) return $ mydecode r2

getFunc :: String -> String -> IO RawPyObject
getFunc s argTypes = do
    currentModules <- readIORef modules
    let key = hash s
    unless (member "initialized" currentModules) initialize
    case lookup key currentModules of
      Just p -> return p
      Nothing -> do
        execInModule key jsonfunc
        execInModule key s
        execInModule key $ "export = jsonfunc('" ++ argTypes ++ "')(export)"
        f' <- getObjectInModule key "export"
        when (f' == nullPtr) $ error "NameError: name 'export' is not defined"
        writeIORef modules (insert (hash s) f' currentModules)
        return f'

newForeignPyPtr :: RawPyObject -> IO (PyObject b)
newForeignPyPtr r = do
    finalizer <- gimmeFunc 0
    PyObject <$> newForeignPtr finalizer r

-- | numpy -> Repa

foreign import ccall "get_PyArray_BYTES" py_PyArray_BYTES :: RawPyObject -> IO (Ptr ())
foreign import ccall "get_PyArray_NDIM" py_PyArray_NDIM :: RawPyObject -> IO CInt
foreign import ccall "get_PyArray_DIMS" py_PyArray_DIMS :: RawPyObject -> IO (Ptr CIntPtr)
foreign import ccall "release_PyArray_BYTES" py_release_PyArray_BYTES :: RawPyObject -> IO ()

extractNumpyArray :: Shape sh => PyObject a -> IO (Array F sh b)
extractNumpyArray (PyObject fp) = do
    arr <- withForeignPtr fp $ \p -> do
      s <- shape p
      -- print $ showShape s
      buf <- py_PyArray_BYTES p
      py_release_PyArray_BYTES p
      fp' <- newForeignPtr finalizerFree buf
      return $ fromForeignPtr s (castForeignPtr fp')
    return arr
        where
          shape :: Shape sh => RawPyObject -> IO sh
          shape ptr = do
            ndim <- fromIntegral <$> py_PyArray_NDIM ptr
            dims <- peekArray ndim =<< py_PyArray_DIMS ptr
            -- return $ shapeOfList (reverse [fromIntegral d | d <- dims])
            return $ shapeOfList [fromIntegral d | d <- dims]

-- | Matrix -> numpy

foreign import ccall "matrix3x3_to_pyobject" py_matrix_to_pyobject :: Ptr Double -> IO RawPyObject

matrixToPyObject :: Matrix Double -> IO (PyObject a)
matrixToPyObject m = withArray (toList . flatten $ m) $ \buff -> do
  newForeignPyPtr =<< py_matrix_to_pyobject buff

def1 :: String -> String -> IO (PyObject b)
def1 s argTypes = do
    f <- getFunc s argTypes
    r <- pyObject_CallObject f nullPtr
    checkError s
    newForeignPyPtr r

def' :: String -> RawPyObject -> RawPyObject -> IO (PyObject b)
def' s p1 f = do
  (PyObject fp) <- newForeignPyPtr p1
  r <- withForeignPtr fp $ \p -> pyObject_CallObject f p
  checkError s
  newForeignPyPtr r

def2 :: String -> String -> PyObject a -> IO (PyObject b)
def2 s argTypes (PyObject fx1) = do
    f <- getFunc s argTypes
    p1 <- withForeignPtr fx1 $ \x1 -> withCString "(O)" (`py_BuildValueObject` x1)
    def' s p1 f

def3 :: String -> String -> PyObject a1 -> PyObject a2 -> IO (PyObject b)
def3 s argTypes (PyObject fx1) (PyObject fx2) = do
    f <- getFunc s argTypes
    p1 <- withForeignPtr fx1 $ \x1 -> (
        withForeignPtr fx2 $ \x2 -> (
            withCString "(OO)" (\cs -> py_BuildValueObject2 cs x1 x2)
        ))
    def' s p1 f

def4 :: String -> String -> PyObject a1 -> PyObject a2 -> PyObject a3 -> IO (PyObject b)
def4 s argTypes (PyObject fx1) (PyObject fx2) (PyObject fx3) = do
    f <- getFunc s argTypes
    p1 <- withForeignPtr fx1 $ \x1 -> (
        withForeignPtr fx2 $ \x2 -> (
            withForeignPtr fx3 $ \x3 -> (
                withCString "(OOO)" (\cs -> py_BuildValueObject3 cs x1 x2 x3)
        )))
    def' s p1 f

def5 :: String -> String -> PyObject a1 -> PyObject a2 -> PyObject a3 -> PyObject a4 -> IO (PyObject b)
def5 s argTypes (PyObject fx1) (PyObject fx2) (PyObject fx3) (PyObject fx4) = do
    f <- getFunc s argTypes
    p1 <- withForeignPtr fx1 $ \x1 -> (
        withForeignPtr fx2 $ \x2 -> (
            withForeignPtr fx3 $ \x3 -> (
                withForeignPtr fx4 $ \x4 -> (
                    withCString "(OOOO)" (\cs -> py_BuildValueObject4 cs x1 x2 x3 x4)
        ))))
    def' s p1 f

defO :: String -> IO (PyObject b)
defO s  = def1 s "O"

defV :: (FromJSON b) => String -> IO b
defV s  = fromPyObject =<< def1 s "V"

defOO :: Partial => String -> PyObject a1 -> IO (PyObject b)
defOO s = def2 s "OO"

defOV :: (FromJSON b) => String -> PyObject a1 -> IO b
defOV s x1 = fromPyObject =<< def2 s "OV" x1

defVO :: (ToJSON a1) => String -> a1 -> IO (PyObject b)
defVO s input1 = do
    x1 <- toPyObject input1
    def2 s "VO" x1

defVV :: (ToJSON a1, FromJSON b) => String -> a1 -> IO b
defVV s input1 = do
    x1 <- toPyObject input1
    fromPyObject =<< def2 s "VV" x1

defOOO :: Partial => String -> PyObject a1 -> PyObject a2 -> IO (PyObject b)
defOOO s = def3 s "OOO"

defOOV :: (FromJSON b) => String -> PyObject a1 -> PyObject a2 -> IO b
defOOV s x1 x2 = fromPyObject =<< def3 s "OOV" x1 x2

defOVO :: (ToJSON a2) => String -> PyObject a1 -> a2 -> IO (PyObject b)
defOVO s x1 input2 = do
    x2 <- toPyObject input2
    def3 s "OVO" x1 x2

defOVV :: (ToJSON a2, FromJSON b) => String -> PyObject a1 -> a2 -> IO b
defOVV s x1 input2 = do
    x2 <- toPyObject input2
    fromPyObject =<< def3 s "OVV" x1 x2

defVOO :: (ToJSON a1) => String -> a1 -> PyObject a2 -> IO (PyObject b)
defVOO s input1 x2 = do
    x1 <- toPyObject input1
    def3 s "VOO" x1 x2

defVOV :: (ToJSON a1, FromJSON b) => String -> a1 -> PyObject a2 -> IO b
defVOV s input1 x2 = do
    x1 <- toPyObject input1
    fromPyObject =<< def3 s "VOV" x1 x2

defVVO :: (ToJSON a1, ToJSON a2) => String -> a1 -> a2 -> IO (PyObject b)
defVVO s input1 input2 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    def3 s "VVO" x1 x2

defVVV :: (ToJSON a1, ToJSON a2, FromJSON b) => String -> a1 -> a2 -> IO b
defVVV s input1 input2 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    fromPyObject =<< def3 s "VVV" x1 x2

defOOOO :: Partial => String -> PyObject a1 -> PyObject a2 -> PyObject a3 -> IO (PyObject b)
defOOOO s = def4 s "OOOO"

defOOOV :: (FromJSON b) => String -> PyObject a1 -> PyObject a2 -> PyObject a3 -> IO b
defOOOV s x1 x2 x3 = fromPyObject =<< def4 s "OOOV" x1 x2 x3

defOOVO :: (ToJSON a3) => String -> PyObject a1 -> PyObject a2 -> a3 -> IO (PyObject b)
defOOVO s x1 x2 input3 = do
    x3 <- toPyObject input3
    def4 s "OOVO" x1 x2 x3

defOOVV :: (ToJSON a3, FromJSON b) => String -> PyObject a1 -> PyObject a2 -> a3 -> IO b
defOOVV s x1 x2 input3 = do
    x3 <- toPyObject input3
    fromPyObject =<< def4 s "OOVV" x1 x2 x3

defOVOO :: (ToJSON a2) => String -> PyObject a1 -> a2 -> PyObject a3 -> IO (PyObject b)
defOVOO s x1 input2 x3 = do
    x2 <- toPyObject input2
    def4 s "OVOO" x1 x2 x3

defOVOV :: (ToJSON a2, FromJSON b) => String -> PyObject a1 -> a2 -> PyObject a3 -> IO b
defOVOV s x1 input2 x3 = do
    x2 <- toPyObject input2
    fromPyObject =<< def4 s "OVOV" x1 x2 x3

defOVVO :: (ToJSON a2, ToJSON a3) => String -> PyObject a1 -> a2 -> a3 -> IO (PyObject b)
defOVVO s x1 input2 input3 = do
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    def4 s "OVVO" x1 x2 x3

defOVVV :: (ToJSON a2, ToJSON a3, FromJSON b) => String -> PyObject a1 -> a2 -> a3 -> IO b
defOVVV s x1 input2 input3 = do
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    fromPyObject =<< def4 s "OVVV" x1 x2 x3

defVOOO :: (ToJSON a1) => String -> a1 -> PyObject a2 -> PyObject a3 -> IO (PyObject b)
defVOOO s input1 x2 x3 = do
    x1 <- toPyObject input1
    def4 s "VOOO" x1 x2 x3

defVOOV :: (ToJSON a1, FromJSON b) => String -> a1 -> PyObject a2 -> PyObject a3 -> IO b
defVOOV s input1 x2 x3 = do
    x1 <- toPyObject input1
    fromPyObject =<< def4 s "VOOV" x1 x2 x3

defVOVO :: (ToJSON a1, ToJSON a3) => String -> a1 -> PyObject a2 -> a3 -> IO (PyObject b)
defVOVO s input1 x2 input3 = do
    x1 <- toPyObject input1
    x3 <- toPyObject input3
    def4 s "VOVO" x1 x2 x3

defVOVV :: (ToJSON a1, ToJSON a3, FromJSON b) => String -> a1 -> PyObject a2 -> a3 -> IO b
defVOVV s input1 x2 input3 = do
    x1 <- toPyObject input1
    x3 <- toPyObject input3
    fromPyObject =<< def4 s "VOVV" x1 x2 x3

defVVOO :: (ToJSON a1, ToJSON a2) => String -> a1 -> a2 -> PyObject a3 -> IO (PyObject b)
defVVOO s input1 input2 x3 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    def4 s "VVOO" x1 x2 x3

defVVOV :: (ToJSON a1, ToJSON a2, FromJSON b) => String -> a1 -> a2 -> PyObject a3 -> IO b
defVVOV s input1 input2 x3 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    fromPyObject =<< def4 s "VVOV" x1 x2 x3

defVVVO :: (ToJSON a1, ToJSON a2, ToJSON a3) => String -> a1 -> a2 -> a3 -> IO (PyObject b)
defVVVO s input1 input2 input3 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    def4 s "VVVO" x1 x2 x3

defVVVV :: (ToJSON a1, ToJSON a2, ToJSON a3, FromJSON b) => String -> a1 -> a2 -> a3 -> IO b
defVVVV s input1 input2 input3 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    fromPyObject =<< def4 s "VVVV" x1 x2 x3

defVVVVV :: (ToJSON a1, ToJSON a2, ToJSON a3, ToJSON a4, FromJSON b) => String -> a1 -> a2 -> a3 -> a4 -> IO b
defVVVVV s input1 input2 input3 input4 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    x4 <- toPyObject input4
    fromPyObject =<< def5 s "VVVVV" x1 x2 x3 x4

defVVVVO :: (ToJSON a1, ToJSON a2, ToJSON a3, ToJSON a4) => String -> a1 -> a2 -> a3 -> a4 -> IO (PyObject b)
defVVVVO s input1 input2 input3 input4 = do
    x1 <- toPyObject input1
    x2 <- toPyObject input2
    x3 <- toPyObject input3
    x4 <- toPyObject input4
    def5 s "VVVVO" x1 x2 x3 x4