{-# LANGUAGE TemplateHaskell #-}

module Rattletrap.Type.Attribute.MusicStinger where

import Rattletrap.Type.Common
import qualified Rattletrap.Type.U32 as U32
import qualified Rattletrap.Type.U8 as U8
import Rattletrap.Decode.Common
import Rattletrap.Encode.Common

import qualified Data.Binary.Bits.Put as BinaryBits

data MusicStinger = MusicStinger
  { flag :: Bool
  , cue :: U32.U32
  , trigger :: U8.U8
  }
  deriving (Eq, Show)

$(deriveJson ''MusicStinger)

bitPut :: MusicStinger -> BitPut ()
bitPut musicStingerAttribute = do
  BinaryBits.putBool (flag musicStingerAttribute)
  U32.bitPut (cue musicStingerAttribute)
  U8.bitPut (trigger musicStingerAttribute)

bitGet :: BitGet MusicStinger
bitGet =
  MusicStinger
    <$> getBool
    <*> U32.bitGet
    <*> U8.bitGet
