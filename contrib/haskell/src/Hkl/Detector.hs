{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}

module Hkl.Detector
       ( Detector(..)
       , ImXpadS140
       , Xpad32
       , ZeroD
       , coordinates
       ) where

import Data.Vector.Storable ( Vector
                            , fromList
                            )

import Hkl.PyFAI.Npt ( NptPoint ( NptPoint ) )


data ImXpadS140
data Xpad32
data ZeroD

data Detector a where
  ImXpadS140 :: Detector ImXpadS140
  Xpad32 :: Detector Xpad32
  ZeroD :: Detector ZeroD

deriving instance Show (Detector a)

-- | Xpad Family

type Gap = Double
type Width = Int
type Index = Int

-- an xpad line is like this (pixel size, index)
-- | s 0 | s 1 | s 2 | ... |   5/2 s (w - 1)  || 5/2 s w   | s (w + 1) | ...
xpadLine :: Width -> Index -> Double
xpadLine w i'
    | i' == 0        = s / 2
    | i' == 1        = s * 3 / 2
    | idx == 0       = s * (fromIntegral i' + 3 * fromIntegral c - 1 / 4)
    | idx <= (w - 2) = s * (fromIntegral i' + 3 * fromIntegral c + 1 / 2)
    | idx == (w - 1) = s * (fromIntegral i' + 3 * fromIntegral c + 5 / 4)
    | otherwise = error $ "wront coordinates" ++ show i'
    where
      s = 130e-6
      (c, idx) = divMod i' w

xpadLineWithGap :: Width -> Gap -> Index -> Double
xpadLineWithGap w g i' = s / 2 + (s * fromIntegral i') + g * fromIntegral (div i' w)
    where
      s = 130e-6

interp :: (Int -> Double) -> Double -> Double
interp f p
  | p0 == p1  = f p0
  | otherwise = (p - fromIntegral p0) * (f p1 - f p0) + f p0
  where
    p0 :: Int
    p0 = floor p

    p1 :: Int
    p1 = ceiling p

-- compute the coordinated at a given point

coordinates :: Detector a -> NptPoint -> Vector Double
coordinates ZeroD (NptPoint 0 0) = fromList [0, 0, 0]
coordinates ZeroD _ = error "No coordinates in a ZeroD detecteor"

coordinates ImXpadS140 (NptPoint x y) =
  fromList [ interp (xpadLine 120) y
           , interp (xpadLine  80) x
           , 0
           ]

coordinates Xpad32 (NptPoint x y) =
  fromList [ interp (xpadLineWithGap 120 3.57e-3) y
           , interp (xpadLine        80) x
           , 0]
