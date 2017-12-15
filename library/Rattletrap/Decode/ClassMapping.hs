module Rattletrap.Decode.ClassMapping
  ( getClassMapping
  ) where

import Rattletrap.Type.ClassMapping
import Rattletrap.Decode.Word32le
import Rattletrap.Decode.Str

import qualified Data.Binary as Binary

getClassMapping :: Binary.Get ClassMapping
getClassMapping = do
  name <- getText
  streamId <- getWord32
  pure (ClassMapping name streamId)
