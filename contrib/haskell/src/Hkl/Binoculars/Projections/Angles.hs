{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeFamilies        #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

{-
    Copyright  : Copyright (C) 2014-2022 Synchrotron SOLEIL
                                         L'Orme des Merisiers Saint-Aubin
                                         BP 48 91192 GIF-sur-YVETTE CEDEX
    License    : GPL3+

    Maintainer : Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
    Stability  : Experimental
    Portability: GHC only (not tested)
-}

module Hkl.Binoculars.Projections.Angles
    ( DataPath(..)
    , newAngles
    , processAngles
    , updateAngles
    ) where

import           Control.Concurrent.Async          (mapConcurrently)
import           Control.Lens                      (makeLenses)
import           Control.Monad.Catch               (MonadThrow)
import           Control.Monad.IO.Class            (MonadIO (liftIO), liftIO)
import           Control.Monad.Logger              (MonadLogger, logDebug,
                                                    logDebugSH, logErrorSH,
                                                    logInfo)
import           Control.Monad.Reader              (MonadReader, ask)
import           Control.Monad.Trans.Reader        (runReaderT)
import           Data.Aeson                        (FromJSON, ToJSON,
                                                    eitherDecode', encode)
import           Data.Array.Repa                   (Array)
import           Data.Array.Repa.Index             (DIM2, DIM3)
import           Data.Array.Repa.Repr.ForeignPtr   (F, toForeignPtr)
import           Data.ByteString.Lazy              (fromStrict, toStrict)
import           Data.Ini.Config.Bidir             (FieldValue (..), field, ini,
                                                    section, serializeIni, (.=),
                                                    (.=?))
import           Data.Maybe                        (fromMaybe)
import           Data.Text                         (pack)
import           Data.Text.Encoding                (decodeUtf8, encodeUtf8)
import           Data.Text.IO                      (putStr)
import           Data.Typeable                     (typeOf)
import           Foreign.C.Types                   (CDouble (..))
import           Foreign.ForeignPtr                (withForeignPtr)
import           Foreign.Marshal.Array             (withArrayLen)
import           GHC.Conc                          (getNumCapabilities)
import           GHC.Generics                      (Generic)
import           Numeric.Units.Dimensional.Prelude (degree, meter, (*~))
import           Path                              (Abs, Dir, Path)
import           Pipes                             (Pipe, each, runEffect,
                                                    (>->))
import           Pipes.Prelude                     (map, tee, toListM)
import           Pipes.Safe                        (MonadSafe, runSafeT)
import           Text.Printf                       (printf)

import           Hkl.Binoculars.Common
import           Hkl.Binoculars.Config
import           Hkl.Binoculars.Pipes
import           Hkl.Binoculars.Projections
import           Hkl.Binoculars.Projections.QxQyQz
import           Hkl.C.Binoculars
import           Hkl.Detector
import           Hkl.Image


--------------
-- DataPath --
--------------

data instance DataPath 'AnglesProjection = DataPathAngles
  { dataPathAnglesQxQyQz :: DataPath 'QxQyQzProjection }
  deriving (Eq, Generic, ToJSON, FromJSON)

instance Show (DataPath 'AnglesProjection) where
  show = show . typeOf

instance HasFieldValue (DataPath 'AnglesProjection) where
  fieldvalue = FieldValue
               { fvParse = eitherDecode' . fromStrict . encodeUtf8
               , fvEmit = decodeUtf8 . toStrict . encode
               }

defaultDataPathAngles :: DataPath 'AnglesProjection
defaultDataPathAngles = DataPathAngles defaultDataPathQxQyQz

------------
-- Config --
------------

data instance Config 'AnglesProjection = BinocularsConfigAngles
  { _binocularsConfigAnglesNcore                  :: Maybe Int
  , _binocularsConfigAnglesDestination            :: DestinationTmpl
  , _binocularsConfigAnglesOverwrite              :: Bool
  , _binocularsConfigAnglesInputType              :: InputType
  , _binocularsConfigAnglesNexusdir               :: Maybe (Path Abs Dir)
  , _binocularsConfigAnglesTmpl                   :: Maybe InputTmpl
  , _binocularsConfigAnglesInputRange             :: Maybe ConfigRange
  , _binocularsConfigAnglesDetector               :: Maybe (Detector Hkl DIM2)
  , _binocularsConfigAnglesCentralpixel           :: (Int, Int)
  , _binocularsConfigAnglesSdd                    :: Meter
  , _binocularsConfigAnglesDetrot                 :: Maybe Degree
  , _binocularsConfigAnglesAttenuationCoefficient :: Maybe Double
  , _binocularsConfigAnglesMaskmatrix             :: Maybe MaskLocation
  , _binocularsConfigAnglesWavelength             :: Maybe Angstrom
  , _binocularsConfigAnglesProjectionType         :: ProjectionType
  , _binocularsConfigAnglesProjectionResolution   :: [Double]
  , _binocularsConfigAnglesProjectionLimits       :: Maybe [Limits]
  , _binocularsConfigAnglesDataPath               :: Maybe (DataPath 'AnglesProjection)
  } deriving (Eq, Show)

makeLenses 'BinocularsConfigAngles

instance HasIniConfig 'AnglesProjection where
  defaultConfig = BinocularsConfigAngles
    { _binocularsConfigAnglesNcore = Nothing
    , _binocularsConfigAnglesDestination = DestinationTmpl "."
    , _binocularsConfigAnglesOverwrite = False
    , _binocularsConfigAnglesInputType = SixsFlyScanUhv
    , _binocularsConfigAnglesNexusdir = Nothing
    , _binocularsConfigAnglesTmpl = Nothing
    , _binocularsConfigAnglesInputRange  = Nothing
    , _binocularsConfigAnglesDetector = Nothing
    , _binocularsConfigAnglesCentralpixel = (0, 0)
    , _binocularsConfigAnglesSdd = Meter (1 *~ meter)
    , _binocularsConfigAnglesDetrot = Nothing
    , _binocularsConfigAnglesAttenuationCoefficient = Nothing
    , _binocularsConfigAnglesMaskmatrix = Nothing
    , _binocularsConfigAnglesWavelength = Nothing
    , _binocularsConfigAnglesProjectionType = AnglesProjection
    , _binocularsConfigAnglesProjectionResolution = [1, 1, 1]
    , _binocularsConfigAnglesProjectionLimits  = Nothing
    , _binocularsConfigAnglesDataPath = Just defaultDataPathAngles
    }

  specConfig = do
    section "dispatcher" $ do
      binocularsConfigAnglesNcore .=? field "ncores" auto
      binocularsConfigAnglesDestination .= field "destination" auto
      binocularsConfigAnglesOverwrite .= field "overwrite" auto
    section "input" $ do
      binocularsConfigAnglesInputType .= field "type" auto
      binocularsConfigAnglesNexusdir .=? field "nexusdir" auto
      binocularsConfigAnglesTmpl .=? field "inputtmpl" auto
      binocularsConfigAnglesInputRange .=? field "inputrange" auto
      binocularsConfigAnglesDetector .=? field "detector" auto
      binocularsConfigAnglesCentralpixel .= field "centralpixel" auto
      binocularsConfigAnglesSdd .= field "sdd" auto
      binocularsConfigAnglesDetrot .=? field "detrot" auto
      binocularsConfigAnglesAttenuationCoefficient .=? field "attenuation_coefficient" auto
      binocularsConfigAnglesMaskmatrix .=? field "maskmatrix" auto
      binocularsConfigAnglesWavelength .=? field "wavelength" auto
      binocularsConfigAnglesDataPath .=? field "datapath" auto
    section "projection" $ do
      binocularsConfigAnglesProjectionType .= field "type" auto
      binocularsConfigAnglesProjectionResolution .= field "resolution" auto
      binocularsConfigAnglesProjectionLimits .=? field "limits" auto

  overwriteInputRange mr c = case mr of
                               Nothing  -> c
                               (Just _) -> c{_binocularsConfigAnglesInputRange = mr}


-------------------------
-- Angles Projection --
-------------------------

newtype DataFrameAngles = DataFrameAngles DataFrameQxQyQz

{-# INLINE spaceAngles #-}
spaceAngles :: Detector a DIM2 -> Array F DIM3 Double -> Resolutions -> Maybe Mask -> Maybe [Limits] -> Space DIM2 -> DataFrameAngles -> IO (DataFrameSpace DIM2)
spaceAngles det pixels rs mmask' mlimits space@(Space fSpace) (DataFrameAngles (DataFrameQxQyQz _ att g img)) =
  withNPixels det $ \nPixels ->
  withGeometry g $ \geometry ->
  withForeignPtr (toForeignPtr pixels) $ \pix ->
  withArrayLen rs $ \nr r ->
  withPixelsDims pixels $ \ndim dims ->
  withMaybeMask mmask' $ \ mask'' ->
  withMaybeLimits mlimits rs $ \nlimits limits ->
  withForeignPtr fSpace $ \pSpace -> do
  case img of
    (ImageInt32 fp) -> withForeignPtr fp $ \i -> do
      {-# SCC "hkl_binoculars_space_angles_int32_t" #-} c'hkl_binoculars_space_angles_int32_t pSpace geometry i nPixels (CDouble att) pix (toEnum ndim) dims r (toEnum nr) mask'' limits (toEnum nlimits)
    (ImageWord16 fp) -> withForeignPtr fp $ \i -> do
      {-# SCC "hkl_binoculars_space_angles_uint16_t" #-} c'hkl_binoculars_space_angles_uint16_t pSpace geometry i nPixels (CDouble att) pix (toEnum ndim) dims r (toEnum nr) mask'' limits (toEnum nlimits)
    (ImageWord32 fp) -> withForeignPtr fp $ \i -> do
      {-# SCC "hkl_binoculars_space_angles_uint32_t" #-} c'hkl_binoculars_space_angles_uint32_t pSpace geometry i nPixels (CDouble att) pix (toEnum ndim) dims r (toEnum nr) mask'' limits (toEnum nlimits)

  return (DataFrameSpace img space att)

----------
-- Pipe --
----------

getResolution' :: MonadThrow m => (Config 'AnglesProjection) -> m [Double]
getResolution' c = getResolution (_binocularsConfigAnglesProjectionResolution c) 3

class ChunkP a => FramesAnglesP a where
  framesAnglesP :: MonadSafe m
                  => a -> Detector b DIM2 -> Pipe (FilePath, [Int]) DataFrameAngles m ()

class (FramesAnglesP a, Show a) => ProcessAnglesP a where
  processAnglesP :: (MonadIO m, MonadLogger m, MonadReader (Config 'AnglesProjection) m, MonadThrow m)
                   => m a -> m ()
  processAnglesP mkPaths = do
    (conf :: (Config 'AnglesProjection)) <- ask
    let det = fromMaybe defaultDetector (_binocularsConfigAnglesDetector conf)
    let output' = case _binocularsConfigAnglesInputRange conf of
                   Just r  -> destination' r (_binocularsConfigAnglesDestination conf)
                   Nothing -> destination' (ConfigRange []) (_binocularsConfigAnglesDestination conf)
    let centralPixel' = _binocularsConfigAnglesCentralpixel conf
    let (Meter sampleDetectorDistance) = _binocularsConfigAnglesSdd conf
    let (Degree detrot) = fromMaybe (Degree (0 *~ degree)) ( _binocularsConfigAnglesDetrot conf)
    let mlimits = _binocularsConfigAnglesProjectionLimits conf

    h5d <- mkPaths
    filenames <- InputList
                <$> files (_binocularsConfigAnglesNexusdir conf)
                          (_binocularsConfigAnglesInputRange conf)
                          (_binocularsConfigAnglesTmpl conf)
    mask' <- getMask (_binocularsConfigAnglesMaskmatrix conf) det
    pixels <- liftIO $ getPixelsCoordinates det centralPixel' sampleDetectorDistance detrot
    res <- getResolution' conf

    -- compute the jobs

    let fns = concatMap (replicate 1) (toList filenames)
    chunks <- liftIO $ runSafeT $ toListM $ each fns >-> chunkP h5d
    cap' <-  liftIO $ getNumCapabilities
    let ntot = sum (Prelude.map clength chunks)
    let cap = if cap' >= 2 then cap' - 1 else cap'
    let jobs = chunk (quot ntot cap) chunks

    -- log parameters

    $(logDebugSH) filenames
    $(logDebugSH) h5d
    $(logDebug) "start gessing final cube size"

    -- guess the final cube dimensions (To optimize, do not create the cube, just extract the shape)

    guessed <- liftIO $ withCubeAccumulator EmptyCube $ \c ->
      runSafeT $ runEffect $
      each chunks
      >-> Pipes.Prelude.map (\(Chunk fn f t) -> (fn, [f, (quot (f + t) 4), (quot (f + t) 4) * 2, (quot (f + t) 4) * 3, t]))
      >-> framesAnglesP h5d det
      >-> project det 2 (spaceAngles det pixels res mask' mlimits)
      >-> accumulateP c

    $(logDebug) "stop gessing final cube size"

    -- do the final projection

    $(logInfo) (pack $ printf "let's do a Angles projection of %d %s image(s) on %d core(s)" ntot (show det) cap)

    liftIO $ withProgressBar ntot $ \pb -> do
      r' <- mapConcurrently (\job -> withCubeAccumulator guessed $ \c ->
                               runSafeT $ runEffect $
                               each job
                               >-> Pipes.Prelude.map (\(Chunk fn f t) -> (fn, [f..t]))
                               >-> framesAnglesP h5d det
                               -- >-> filter (\(DataFrameQxQyQz _ _ _ ma) -> isJust ma)
                               >-> project det 2 (spaceAngles det pixels res mask' mlimits)
                               >-> tee (accumulateP c)
                               >-> progress pb
                           ) jobs
      saveCube output' r'

instance ProcessAnglesP (DataPath 'AnglesProjection)

instance ChunkP (DataPath 'AnglesProjection) where
  chunkP (DataPathAngles p) = chunkP p

instance FramesAnglesP (DataPath 'AnglesProjection) where
  framesAnglesP (DataPathAngles qxqyqz) det = framesQxQyQzP qxqyqz det
                                              >->  Pipes.Prelude.map DataFrameAngles

instance FramesQxQyQzP (DataPath 'AnglesProjection) where
  framesQxQyQzP (DataPathAngles p) det = framesQxQyQzP p det

h5dpathAngles :: (MonadLogger m, MonadThrow m)
                => InputType
                -> Maybe Double
                -> m (DataPath 'AnglesProjection)
h5dpathAngles i ma = DataPathAngles <$> (h5dpathQxQyQz i ma)


---------
-- Cmd --
---------

process' :: (MonadLogger m, MonadThrow m, MonadIO m, MonadReader (Config 'AnglesProjection) m)
         => m ()
process' = do
  c <- ask
  processAnglesP (h5dpathAngles (_binocularsConfigAnglesInputType c) (_binocularsConfigAnglesAttenuationCoefficient c))

processAngles :: (MonadLogger m, MonadThrow m, MonadIO m) => Maybe FilePath -> Maybe (ConfigRange) -> m ()
processAngles mf mr = do
  econf <- liftIO $ getConfig mf
  case econf of
    Right conf -> do
      $(logDebug) "config red from the config file"
      $(logDebugSH) conf
      let conf' = overwriteInputRange mr conf
      $(logDebug) "config once overloaded with the command line arguments"
      $(logDebugSH) conf'
      runReaderT process' conf'
    Left e      -> $(logErrorSH) e

newAngles :: (MonadIO m, MonadLogger m, MonadThrow m)
            => Path Abs Dir -> m ()
newAngles cwd = do
  let conf = defaultConfig {_binocularsConfigAnglesNexusdir = Just cwd}
  liftIO $ Data.Text.IO.putStr $ serializeIni (ini conf specConfig)

updateAngles :: (MonadIO m, MonadLogger m, MonadThrow m)
               => Maybe FilePath -> m ()
updateAngles mf = do
  (conf  :: Either String (Config 'AnglesProjection))<- liftIO $ getConfig mf
  $(logDebug) "config red from the config file"
  $(logDebugSH) conf
  case conf of
    Left e      -> $(logErrorSH) e
    Right conf' -> liftIO $ Data.Text.IO.putStr $ serializeIni (ini conf' specConfig)