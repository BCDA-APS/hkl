{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE UnicodeSyntax #-}

module Hkl.Xrd.ZeroD
       ( XrdZeroDCalibration(..)
       , XrdZeroDSample(..)
       , XrdZeroDSource(..)
       , XrdZeroDParams(..)
       ) where

import Data.List (intercalate)
import Data.Text (unlines, pack)
import Numeric.Units.Dimensional.Prelude (meter, nano, (*~))
import System.Exit ( ExitCode( ExitSuccess ) )
import System.FilePath.Posix ((</>), takeFileName)
import Text.Printf ( printf )

import Prelude hiding
    ( any
    , concat
    , head
    , lookup
    , readFile
    , unlines
    )

import Hkl.DataSource
import Hkl.Detector
import Hkl.Edf
import Hkl.Flat
import Hkl.PyFAI
import Hkl.Python
import Hkl.Nxs
import Hkl.Script
import Hkl.Types

-- | Types

data XrdZeroDSource  = XrdZeroDSourceNxs (Nxs XrdZeroD) deriving (Show)

data XrdZeroDSample = XrdZeroDSample SampleName AbsDirPath [XrdZeroDSource] deriving (Show)

data XrdZeroDCalibration a = XrdZeroDCalibration XrdZeroDSample (Detector a) Calibrant deriving (Show)

data XrdZeroDParams a = XrdZeroDParams PoniExt (Maybe (Flat a)) AIMethod deriving (Show)

data XrdZeroDFrame = XrdMeshFrame WaveLength Pose deriving (Show)

edf ∷ AbsDirPath → FilePath → Int → FilePath
edf o n i = o </> f
  where
    f = (takeFileName n) ++ printf "_%02d.edf" i

scriptExtractEdf ∷ AbsDirPath → [XrdZeroDSource] → Script Py2
scriptExtractEdf o es = Py2Script (content, scriptPath)
  where
    content = unlines $
              map Data.Text.pack [ "#!/usr/bin/env python"
                                 , ""
                                 , "from fabio.edfimage import edfimage"
                                 , "from h5py import File"
                                 , ""
                                 , "NEXUSFILES = " ++ toPyVal nxss
                                 , "IDXS = " ++ toPyVal idxs
                                 , "IMAGEPATHS = " ++ toPyVal (imgs ∷ [String])
                                 , "OUTPUTS = " ++ toPyVal outputs
                                 , ""
                                 , "for filename, i, p, o in zip(NEXUSFILES, IDXS, IMAGEPATHS, OUTPUTS):"
                                 , "    with File(filename, mode='r') as f:"
                                 , "        edfimage(f[p][i]).write(o)"
                                 ]

    idx ∷ Int
    idx = 0

    (nxss, idxs, imgs) = unzip3 [(f, idx, img)
                                | (XrdZeroDSourceNxs (Nxs f (XrdZeroDH5Path (DataItemH5 img _) _))) ← es]

    outputs ∷ [FilePath]
    outputs = zipWith (edf o) nxss idxs

    scriptPath ∷ FilePath
    scriptPath = o </> "pre-calibration.py"

scriptPyFAICalib ∷ AbsDirPath → XrdZeroDSource → Detector a → Calibrant → Script Sh
scriptPyFAICalib o e@(XrdZeroDSourceNxs (Nxs n _)) d c = ScriptSh (content, scriptPath)
  where
    content = unlines $
              map Data.Text.pack [ "#!/usr/bin/env sh"
                                 , ""
                                 , "pyFAI-calib " ++ intercalate " " args
                                 ]

    args = [ toPyFAICalibArg (readWavelength e)
           , toPyFAICalibArg c
           , toPyFAICalibArg d
           , toPyFAICalibArg (edf o n i) ]

    scriptPath ∷ FilePath
    scriptPath = o </> (takeFileName n) ++ printf "_%02d.sh" i

    i ∷ Int
    i = 0

readWavelength :: XrdZeroDSource -> WaveLength
readWavelength (XrdZeroDSourceNxs (Nxs _ (XrdZeroDH5Path _ (DataItemConst w)))) = w *~ nano meter

instance ExtractEdf (XrdZeroDCalibration a) where
  extractEdf (XrdZeroDCalibration s d c) = do
    let script = scriptExtractEdf o es
    ExitSuccess ← run script False
    mapM_ go es
    return ()
    where
      go e = scriptSave $ scriptPyFAICalib o e d c

      (XrdZeroDSample _ o es) = s