{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE UnicodeSyntax #-}

module Hkl.Xrd.Mesh
       ( XrdMeshSample(..)
       , XrdMesh'(..)
       , XrdMeshParams(..)
       , XrdMeshSource(..)
       , integrateMesh
       ) where

import Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import Data.Array.Repa (Shape, DIM1, ix1, size)
import Data.Maybe (fromJust)
import Data.Text (Text)
import Data.List (intercalate)
import qualified Data.Text as Text (unlines, pack)
import Data.Vector.Storable (Vector, any, concat, head, singleton)
import Numeric.Units.Dimensional.Prelude (meter, nano, (/~), (*~))
import System.Exit ( ExitCode( ExitSuccess ) )
import System.FilePath ((</>), dropExtension, takeFileName)

import Prelude hiding
    ( any
    , concat
    , head
    , lookup
    , readFile
    , unlines
    )
import Pipes ( lift )

import Hkl.C
import Hkl.DataSource
import Hkl.Detector
import Hkl.Flat
import Hkl.H5
import Hkl.PyFAI
import Hkl.MyMatrix
import Hkl.Nxs
import Hkl.Script
import Hkl.Types
import Hkl.Utils
import Hkl.Xrd.OneD

-- | Types

data XrdMeshSource  = XrdMeshSourceNxs (Nxs XrdMesh)
                    | XrdMeshSourceNxsFly [Nxs XrdMesh]
                    deriving (Show)

data XrdMesh' = XrdMesh DIM1 DIM1 Threshold XrdMeshSource deriving (Show)

data XrdMeshSample = XrdMeshSample SampleName OutputBaseDir [XrdMesh'] -- ^ nxss

data XrdMeshParams a = XrdMeshParams PoniExt (Maybe (Flat a)) AIMethod

data XrdMeshFrame = XrdMeshFrame
                    WaveLength
                    (MyMatrix Double)
                  deriving (Show)

class FrameND t where
  rowND :: t -> MaybeT IO XrdMeshFrame

instance FrameND (DataFrameH5 XrdMesh) where

  rowND (XrdMeshH5 _ _ _ _ _ g d w) = do
    let mu = 0.0
    let komega = 0.0
    let kappa = 0.0
    let kphi = 0.0
    gamma <- get_position' g (ix1 0)
    delta <- get_position' d (ix1 0)
    wavelength <- get_position' w (ix1 0)
    let source@(Source w') = Source (head wavelength *~ nano meter)
    let positions = concat [mu, komega, kappa, kphi, gamma, delta]
    let geometry =  Geometry K6c source positions Nothing
    let detector = ZeroD
    m <- lift $ geometryDetectorRotationGet geometry detector
    return $ XrdMeshFrame w' (MyMatrix HklB m)
    where
      get_position' :: Shape sh => DataSource a -> sh -> MaybeT IO (Vector Double)
      get_position' (DataSourceH5 _ a ) b = lift $ do
        v <- get_position_new a b
        if any isNaN v then fail "File contains Nan" else return v
      get_position' (DataSourceConst v) _ = lift $ return $ singleton v

  rowND (XrdMeshFlyH5 _ _ _ _ _ g d w) = do
    let mu = 0.0
    let komega = 0.0
    let kappa = 0.0
    let kphi = 0.0
    gamma <- get_position' g (ix1 0)
    delta <- get_position' d (ix1 0)
    wavelength <- get_position' w (ix1 0)
    let source@(Source w') = Source (head wavelength *~ nano meter)
    let positions = concat [mu, komega, kappa, kphi, gamma, delta]
    let geometry =  Geometry K6c source positions Nothing
    let detector = ZeroD
    m <- lift $ geometryDetectorRotationGet geometry detector
    return $ XrdMeshFrame w' (MyMatrix HklB m)
    where
      get_position' :: Shape sh => DataSource a -> sh -> MaybeT IO (Vector Double)
      get_position' (DataSourceH5 _ a ) b = lift $ do
        v <- get_position_new a b
        if any isNaN v then fail "File contains Nan" else return v
      get_position' (DataSourceConst v) _ = lift $ return $ singleton v


xrdMeshPy ∷ XrdMeshParams a → FilePath → FilePath → String → String → String → DIM1 → Threshold → WaveLength → FilePath → FilePath → Script Py2
xrdMeshPy (XrdMeshParams _ mflat m) p f x y i b (Threshold t) w o scriptPath = Py2Script (content, scriptPath)
    where
      content = Text.unlines $
                map Text.pack ["#!/bin/env python"
                              , ""
                              , "import numpy"
                              , "from h5py import File"
                              , "from pyFAI import load"
                              , ""
                              , "PONIFILE = " ++ show p
                              , "NEXUSFILE = " ++ show f
                              , "MESHX = " ++ show x
                              , "MESHY = " ++ show y
                              , "IMAGEPATH = " ++ show i
                              , "N = " ++ show (size b)
                              , "OUTPUT = " ++ show o
                              , "WAVELENGTH = " ++ show (w /~ meter)
                              , "THRESHOLD = " ++ show t
                              , ""
                              , "# load the flat"
                              , "flat = " ++ flatValueForPy mflat
                              , ""
                              , "ai = load(PONIFILE)"
                              , "ai.wavelength = WAVELENGTH"
                              , "ai._empty = numpy.nan"
                              , "mask_det = ai.detector.mask"
                              , "mask_module = numpy.zeros_like(mask_det, dtype=bool)"
                              , "mask_module[0:50, :] = True"
                              , "mask_module[910:960, :] = True"
                              , "mask_module[:,0:50] = True"
                              , "mask_module[:,510:560] = True"
                              , "mask_det = numpy.logical_or(mask_det, mask_module)"
                              , "with File(NEXUSFILE, mode='r') as f:"
                              , "    nx = f[MESHX].shape[0]"
                              , "    ny = f[MESHY].shape[0]"
                              , "    imgs = f[IMAGEPATH]"
                              , "    with File(OUTPUT, mode='w') as o:"
                              , "        o.create_dataset('map', shape=(ny, nx, N), dtype='float')"
                              , "        for y in range(ny):"
                              , "            for x in range(nx):"
                              , "                img = imgs[y, x]"
                              , "                mask = numpy.where(img > THRESHOLD, True, False)"
                              , "                mask = numpy.logical_or(mask, mask_det)"
                              , "                tth, I, sigma = ai.integrate1d(img, N, unit=\"2th_deg\","
                              , "                                               error_model=\"poisson\", correctSolidAngle=False,"
                              , "                                               method=\"" ++ show m ++ "\","
                              , "                                               mask=mask, safe=False, flat=flat)"
                              , "                o['map'][y, x] = I"
                              ]

xrdMeshFlyPy ∷ FilePath → [FilePath] → String → String → String → DIM1 → Threshold → WaveLength → AIMethod → FilePath → FilePath → (Text, FilePath)
xrdMeshFlyPy p fs x y i b (Threshold t) w m o os = (script, os)
    where
      script = Text.unlines $
               map Text.pack ["#!/bin/env python"
                             , ""
                             , "import numpy"
                             , "from h5py import File"
                             , "from pyFAI import load"
                             , ""
                             , "PONIFILE = " ++ show p
                             , "NEXUSFILE = [" ++ intercalate ",\n" (map show fs) ++ "]"
                             , "MESHX = " ++ show x
                             , "MESHY = " ++ show y
                             , "IMAGEPATH = " ++ show i
                             , "N = " ++ show (size b)
                             , "OUTPUT = " ++ show o
                             , "WAVELENGTH = " ++ show (w /~ meter)
                             , "THRESHOLD = " ++ show t
                             , ""
                             , "ai = load(PONIFILE)"
                             , "ai.wavelength = WAVELENGTH"
                             , "ai._empty = numpy.nan"
                             , "mask_det = ai.detector.mask"
                             , "mask_module = numpy.zeros_like(mask_det, dtype=bool)"
                             , "mask_module[0:50, :] = True"
                             , "mask_module[910:960, :] = True"
                             , "mask_module[:,0:50] = True"
                             , "mask_module[:,510:560] = True"
                             , "mask_det = numpy.logical_or(mask_det, mask_module)"
                             , "with File(NEXUSFILE, mode='r') as f:"
                             , "    nx = f[MESHX].shape[0]"
                             , "    ny = f[MESHY].shape[0]"
                             , "    imgs = f[IMAGEPATH]"
                             , "    with File(OUTPUT, mode='w') as o:"
                             , "        o.create_dataset('map', shape=(ny, nx, N), dtype='float')"
                             , "        for y in range(ny):"
                             , "            for x in range(nx):"
                             , "                img = imgs[y, x]"
                             , "                mask = numpy.where(img > THRESHOLD, True, False)"
                             , "                mask = numpy.logical_or(mask, mask_det)"
                             , "                tth, I, sigma = ai.integrate1d(img, N, unit=\"2th_deg\","
                             , "                                               error_model=\"poisson\", correctSolidAngle=False,"
                             , "                                               method=\"" ++ show m ++ "\","
                             , "                                               mask=mask, safe=False)"
                             , "                o['map'][y, x] = I"
                             ]

getWaveLengthAndPoniExt ∷ XrdMeshParams a → XrdMeshSource → IO (WaveLength, PoniExt)
getWaveLengthAndPoniExt (XrdMeshParams ref _ _) (XrdMeshSourceNxs nxs) =
  withDataSource nxs $ \h -> do
    -- read the first frame and get the poni used for all the integration.
    d <- runMaybeT $ rowND h
    let (XrdMeshFrame w m) = fromJust d
    let poniext = setPose ref m
    return (w, poniext)
getWaveLengthAndPoniExt (XrdMeshParams ref _ _) (XrdMeshSourceNxsFly (nxs:_)) =
  withDataSource nxs $ \h -> do
    -- read the first frame and get the poni used for all the integration.
    d <- runMaybeT $ rowND h
    let (XrdMeshFrame w m) = fromJust d
    let poniext = setPose ref m
    return (w, poniext)

integrateMesh ∷ XrdMeshParams a → XrdMeshSample → IO ()
integrateMesh p (XrdMeshSample _ output nxss) =
  mapM_ (integrateMesh' p output) nxss

integrateMesh' ∷ XrdMeshParams a → OutputBaseDir → XrdMesh' → IO ()
integrateMesh' p' output (XrdMesh b _ t nxs'@(XrdMeshSourceNxs (Nxs f h5path))) = do
    -- get the poniext for all the scan
    (w, (PoniExt p _)) <- getWaveLengthAndPoniExt p' nxs'

    -- save the poni at the right place.
    let sdir = (dropExtension . takeFileName) f
    let pfilename = output </> sdir </> sdir ++ ".poni"
    pfilename `hasContent` (poniToText p)

    -- create and execute the python script to do the integration.
    let (XrdMeshH5Path (DataItemH5 i _) (DataItemH5 x _) (DataItemH5 y _) _ _ _) = h5path
    let o = output </> sdir </> sdir ++ ".h5"
    let os = output </> sdir </> sdir ++ ".py"
    let script = xrdMeshPy p' pfilename f x y i b t w o os
    ExitSuccess <- run script False

    return ()
-- integrateMesh' ref output (XrdMesh b _ t ss) = do
--     -- get the poniext for all the scan
--     (w, PoniExt p _) <- getWaveLengthAndPoniExt ref ss

--     -- save this poni at the right place
--     let (XrdMeshSourceNxsFly (Nxs _ nxentry h5path:_)) = ss
--     let pfilename = output </> nxentry </> nxentry ++ ".poni"
--     saveScript (poniToText p) pfilename

--     -- create the python script to do the integration
--     let (XrdMeshH5Path' (DataItemH5 i _) (DataItemH5 x _) (DataItemH5 y _) _ _ _) = h5path
--     let o = output </> nxentry </> nxentry ++ ".h5"
--     let os = output </> nxentry </> nxentry ++ ".py"

--     -- let (script, scriptPath) = xrdMeshFlyPy
--     -- save it
--     -- run it
--     return ()