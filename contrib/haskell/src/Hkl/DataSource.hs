{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE TypeFamilies          #-}
{-
    Copyright  : Copyright (C) 2014-2022 Synchrotron SOLEIL
                                         L'Orme des Merisiers Saint-Aubin
                                         BP 48 91192 GIF-sur-YVETTE CEDEX
    License    : GPL3+

    Maintainer : Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
    Stability  : Experimental
    Portability: GHC only (not tested)
-}

module Hkl.DataSource
  ( DataSource(..)
  , DataSourcePath(..)
  , Is0DStreamable(..)
  , Is1DStreamable(..)
  ) where

import           Bindings.HDF5.Core                (Location)
import           Bindings.HDF5.Dataset             (getDatasetType)
import           Bindings.HDF5.Datatype            (getTypeSize, nativeTypeOf,
                                                    typeIDsEqual)
import           Control.Exception                 (throwIO)
import           Control.Monad                     (forever)
import           Control.Monad.Catch               (tryJust)
import           Control.Monad.Extra               (ifM)
import           Control.Monad.IO.Class            (MonadIO (liftIO))
import           Control.Monad.Trans.Cont          (cont, runCont)
import           Data.Aeson                        (FromJSON (..), ToJSON (..))
import           Data.Array.Repa                   (Shape, size)
import           Data.Array.Repa.Index             (DIM1, DIM2, Z)
import           Data.IORef                        (IORef, readIORef)
import           Data.Int                          (Int32)
import           Data.Vector.Storable              (Vector, fromList)
import           Data.Word                         (Word16, Word32)
import           GHC.Base                          (returnIO)
import           GHC.Float                         (float2Double)
import           GHC.Generics                      (Generic)
import           Numeric.Units.Dimensional.NonSI   (angstrom)
import           Numeric.Units.Dimensional.Prelude (degree, (*~))
import           Pipes                             (Consumer, Pipe, Proxy,
                                                    await, yield)
import           Pipes.Prelude                     (mapM)
import           Pipes.Safe                        (MonadSafe, SomeException,
                                                    bracket, catchP,
                                                    displayException)
import           System.ProgressBar                (Progress (..), ProgressBar,
                                                    Style (..), defStyle,
                                                    elapsedTime, incProgress,
                                                    newProgressBar,
                                                    renderDuration,
                                                    updateProgress)

import           Prelude                           hiding (filter)

import           Hkl.Binoculars.Common
import           Hkl.Binoculars.Config
import           Hkl.C.Binoculars
import           Hkl.C.Geometry
import           Hkl.Detector
import           Hkl.H5
import           Hkl.Image
import           Hkl.Pipes
import           Hkl.Types

-- Is0DStreamable

class Is0DStreamable a e where
  extract0DStreamValue :: a -> IO e

instance Is0DStreamable Dataset Double where
  extract0DStreamValue d = get_position d 0

instance Is0DStreamable (DataSourceAcq Degree) Degree where
    extract0DStreamValue (DataSourceAcq'Degree d) =
        Degree <$> do
          v <- extract0DStreamValue d
          return $ v *~ degree

instance Is0DStreamable (DataSourceAcq Degree) Double where
  extract0DStreamValue (DataSourceAcq'Degree d) = extract0DStreamValue d

instance Is0DStreamable (DataSourceAcq NanoMeter) NanoMeter where
    extract0DStreamValue (DataSourceAcq'NanoMeter d) =
        NanoMeter <$> do
          v <- extract0DStreamValue d
          return $ v *~ angstrom

instance Is0DStreamable (DataSourceAcq WaveLength) WaveLength where
  extract0DStreamValue (DataSourceAcq'WaveLength d) = do
    v <- extract0DStreamValue d
    return $ v *~ angstrom
  extract0DStreamValue (DataSourceAcq'WaveLengthConst a) = return $ unAngstrom a

instance Is0DStreamable (DataSourceAcq WaveLength) Source where
  extract0DStreamValue d = Source <$> extract0DStreamValue d

-- Is1DStreamable

class Is1DStreamable a e where
  extract1DStreamValue :: a -> Int -> IO e

-- Is1DStreamable (instances)

instance Is1DStreamable Dataset Attenuation where
  extract1DStreamValue d i = Attenuation <$> extract1DStreamValue d i

-- instance Is1DStreamable (DataSourceAcq Degree) Degree where
--   extract1DStreamValue (DataSourceAcqDegree d) i = Degree <$> do
--     v <- extract1DStreamValue d i
--     return $ v *~ degree

instance Is1DStreamable (DataSourceAcq Degree) Double where
  extract1DStreamValue (DataSourceAcq'Degree d) = extract1DStreamValue d

instance Is1DStreamable Dataset Double where
  extract1DStreamValue = get_position

instance Is1DStreamable Dataset Float where
  extract1DStreamValue = get_position

instance Is1DStreamable (DataSourceAcq NanoMeter) NanoMeter where
  extract1DStreamValue (DataSourceAcq'NanoMeter d) i = NanoMeter <$> do
    v <- extract1DStreamValue d i
    return $ v *~ angstrom

instance Is1DStreamable Dataset WaveLength where
  extract1DStreamValue d i = do
    v <- extract1DStreamValue d i
    return $ v *~ angstrom

instance Is1DStreamable Dataset Source where
  extract1DStreamValue d i = Source <$> extract1DStreamValue d i

instance Is1DStreamable  [Dataset] (Data.Vector.Storable.Vector Double) where
  extract1DStreamValue ds i = fromList <$> Prelude.mapM (`extract1DStreamValue` i) ds

-- DataSource

data family DataSourcePath a :: *
data family DataSourceAcq a :: *

class DataSource a where
  withDataSourceP :: (Location l, MonadSafe m) => l -> DataSourcePath a -> (DataSourceAcq a -> m r) -> m r

-- | DataSource (instances)

-- Degree

data instance DataSourcePath Degree = DataSourcePath'Degree (Hdf5Path DIM1 Double)
  deriving (Eq, Generic, Show)
deriving instance FromJSON (DataSourcePath Degree)
deriving instance ToJSON (DataSourcePath Degree)

data instance DataSourceAcq Degree = DataSourceAcq'Degree Dataset

instance DataSource Degree where
  withDataSourceP f (DataSourcePath'Degree p) g = withHdf5PathP f p $ \ds -> g (DataSourceAcq'Degree ds)

-- NanoMeter

data instance DataSourcePath NanoMeter = DataSourcePath'NanoMeter (Hdf5Path Z Double)
  deriving (Eq, Generic, Show)
deriving instance FromJSON (DataSourcePath NanoMeter)
deriving instance ToJSON (DataSourcePath NanoMeter)

data instance DataSourceAcq NanoMeter = DataSourceAcq'NanoMeter Dataset

instance DataSource NanoMeter where
  withDataSourceP f (DataSourcePath'NanoMeter p) g = withHdf5PathP f p $ \ds -> g (DataSourceAcq'NanoMeter ds)

-- WaveLength

data instance DataSourcePath WaveLength = DataSourcePath'WaveLength (Hdf5Path Z Double)
                                        | DataSourcePath'WaveLengthConst Angstrom
  deriving (Eq, Generic, Show)
deriving instance FromJSON (DataSourcePath WaveLength)
deriving instance ToJSON (DataSourcePath WaveLength)

data instance DataSourceAcq WaveLength = DataSourceAcq'WaveLength Dataset
                                       | DataSourceAcq'WaveLengthConst Angstrom

instance DataSource WaveLength where
    withDataSourceP f (DataSourcePath'WaveLength p) g = withHdf5PathP f p $ \ds -> g (DataSourceAcq'WaveLength ds)
    withDataSourceP _ (DataSourcePath'WaveLengthConst a) g = g (DataSourceAcq'WaveLengthConst a)