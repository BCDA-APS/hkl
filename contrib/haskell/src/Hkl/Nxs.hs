{-# LANGUAGE CPP #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UnicodeSyntax #-}

module Hkl.Nxs
    ( DataFrameH5(..)
    , DataFrameH5Path(..)
    , NxEntry
    , Nxs(..)
    , PoniGenerator
    , XrdFlat
    , XrdOneD
    , XrdMesh
    , mkNxs
    , withDataFrameH5
    , withDataSource
    ) where

#if __GLASGOW_HASKELL__ < 710
import Control.Applicative ((<$>), (<*>))
#endif
import Control.Exception.Base (bracket)
import Control.Monad.IO.Class (liftIO)
import Pipes.Safe ( MonadSafe, bracket )

import Hkl.DataSource
import Hkl.H5
import Hkl.PyFAI

type NxEntry = String

-- to remove an put directly into OneD
type PoniGenerator = Pose -> Int -> IO PoniExt

data XrdFlat
data XrdOneD
data XrdMesh

data DataFrameH5Path a where
  XrdFlatH5Path ∷ (DataItem H5) -- ^ image
                → DataFrameH5Path XrdFlat
  XrdOneDH5Path ∷ (DataItem H5) -- ^ image
                → (DataItem H5) -- ^ gamma
                → (DataItem H5) -- ^ delta
                → (DataItem H5) -- ^ wavelength
                → DataFrameH5Path XrdOneD
  XrdMeshH5Path ∷ (DataItem H5) -- ^ Image
                → (DataItem H5) -- ^ meshx
                → (DataItem H5) -- ^ meshy
                → (DataItem H5) -- ^ gamma
                → (DataItem H5) -- ^ delta
                → (DataItem H5) -- ^ wavelength
                → DataFrameH5Path XrdMesh
  XrdMeshFlyH5Path ∷ (DataItem H5) -- ^ Image
                   → (DataItem H5) -- ^ meshx
                   → (DataItem H5) -- ^ meshy
                   → (DataItem Double) -- ^ gamma
                   → (DataItem Double) -- ^ delta
                   → (DataItem Double) -- ^ wavelength
                   → DataFrameH5Path XrdMesh

deriving instance Show (DataFrameH5Path a)

data Nxs a where
  Nxs ∷ FilePath → DataFrameH5Path a → Nxs a

deriving instance Show (Nxs a)

data DataFrameH5 a where
  XrdFlatH5 ∷ (Nxs XrdFlat) -- Nexus Source file
            → File -- h5file handler
            → (DataSource H5) --images
            → DataFrameH5 XrdFlat
  DataFrameH5 ∷ (Nxs XrdOneD) -- Nexus file
              → File -- h5file handler
              → (DataSource H5) -- gamma
              → (DataSource H5) -- delta
              → (DataSource H5) -- wavelength
              → PoniGenerator -- ponie generator
              → DataFrameH5 XrdOneD
  XrdMeshH5 ∷ (Nxs XrdMesh) -- NexusFile Source File
            → File -- h5file handler
            → (DataSource H5) -- image
            → (DataSource H5) -- meshx
            → (DataSource H5) -- meshy
            → (DataSource H5) -- gamma
            → (DataSource H5) -- delta
            → (DataSource H5) -- wavelength
            → DataFrameH5 XrdMesh
  XrdMeshFlyH5 ∷ (Nxs XrdMesh) -- NexusFile Source File
               → File -- h5file handler
               → (DataSource H5) -- image
               → (DataSource H5) -- meshx
               → (DataSource H5) -- meshy
               → (DataSource Double) -- gamma
               → (DataSource Double) -- delta
               → (DataSource Double) -- wavelength
               → DataFrameH5 XrdMesh

mkNxs ∷ FilePath → NxEntry → (NxEntry → DataFrameH5Path a) → Nxs a
mkNxs f e h = Nxs f (h e)

-- | Instanciate a DataFrameH5 from a DataFrameH5Path
-- acquire and release the resources

after ∷ DataFrameH5 a → IO ()
after (XrdFlatH5 _ f i) = do
  closeDataSource i
  closeFile f
after (DataFrameH5 _ f g d w _) = do
  closeDataSource g
  closeDataSource d
  closeDataSource w
  closeFile f
after (XrdMeshH5 _ f i x y g d w) = do
  closeDataSource i
  closeDataSource x
  closeDataSource y
  closeDataSource g
  closeDataSource d
  closeDataSource w
  closeFile f
after (XrdMeshFlyH5 _ f i x y g d w) = do
  closeDataSource i
  closeDataSource x
  closeDataSource y
  closeDataSource g
  closeDataSource d
  closeDataSource w
  closeFile f

before :: Nxs XrdMesh → IO (DataFrameH5 XrdMesh)
before nxs'@(Nxs f (XrdMeshH5Path i x y g d w)) = do
  h ← openH5 f
  XrdMeshH5
    <$> return nxs'
    <*> return h
    <*> openDataSource h i
    <*> openDataSource h x
    <*> openDataSource h y
    <*> openDataSource h g
    <*> openDataSource h d
    <*> openDataSource h w
before nxs'@(Nxs f (XrdMeshFlyH5Path i x y g d w))= do
  h ← openH5 f
  XrdMeshFlyH5
    <$> return nxs'
    <*> return h
    <*> openDataSource h i
    <*> openDataSource h x
    <*> openDataSource h y
    <*> openDataSource h g
    <*> openDataSource h d
    <*> openDataSource h w

withDataSource :: Nxs XrdMesh -> (DataFrameH5 XrdMesh -> IO r) -> IO r
withDataSource s = Control.Exception.Base.bracket (before s) after

-- | Pipe

withDataFrameH5 :: (MonadSafe m) => Nxs XrdOneD -> PoniGenerator -> (DataFrameH5 XrdOneD -> m r) -> m r
withDataFrameH5 nxs'@(Nxs f (XrdOneDH5Path _ g d w)) gen = Pipes.Safe.bracket (liftIO before') (liftIO . after)
  where
    -- before :: File -> DataFrameH5Path -> m DataFrameH5
    before' :: IO (DataFrameH5 XrdOneD)
    before' =  do
      h ← openH5 f
      DataFrameH5
        <$> return nxs'
        <*> return h
        <*> openDataSource h g
        <*> openDataSource h d
        <*> openDataSource h w
        <*> return gen