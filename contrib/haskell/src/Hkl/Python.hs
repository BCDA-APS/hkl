{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UnicodeSyntax #-}

module Hkl.Python
       ( PyVal(..) )
       where

import Data.List (intercalate)

class PyVal a where
  toPyVal ∷ a → String

instance PyVal a ⇒ PyVal (Maybe a) where
  toPyVal (Just v) = toPyVal v
  toPyVal Nothing  = "None"

instance PyVal String where
  toPyVal s = show s

instance PyVal [String] where
  toPyVal vs = "[" ++ intercalate ",\n" (map toPyVal vs) ++ "]"

instance PyVal Int where
  toPyVal i = show i

instance PyVal [Int] where
  toPyVal is = "[" ++ intercalate ",\n" (map toPyVal is) ++ "]"

instance PyVal Double where
  toPyVal d = show d