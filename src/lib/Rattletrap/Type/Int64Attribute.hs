{-# LANGUAGE TemplateHaskell #-}

module Rattletrap.Type.Int64Attribute where

import Rattletrap.Type.Common
import Rattletrap.Type.Int64le

import qualified Data.Binary.Bits.Put as BinaryBits

newtype Int64Attribute = Int64Attribute
  { int64AttributeValue :: Int64le
  } deriving (Eq, Ord, Show)

$(deriveJson ''Int64Attribute)

putInt64Attribute :: Int64Attribute -> BinaryBits.BitPut ()
putInt64Attribute int64Attribute =
  putInt64Bits (int64AttributeValue int64Attribute)
