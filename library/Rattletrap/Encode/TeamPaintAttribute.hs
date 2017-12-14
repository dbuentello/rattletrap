module Rattletrap.Encode.TeamPaintAttribute
  ( putTeamPaintAttribute
  ) where

import Rattletrap.Type.TeamPaintAttribute
import Rattletrap.Encode.Word8
import Rattletrap.Encode.Word32

import qualified Data.Binary.Bits.Put as BinaryBit

putTeamPaintAttribute :: TeamPaintAttribute -> BinaryBit.BitPut ()
putTeamPaintAttribute teamPaintAttribute = do
  putWord8Bits (teamPaintAttributeTeam teamPaintAttribute)
  putWord8Bits (teamPaintAttributePrimaryColor teamPaintAttribute)
  putWord8Bits (teamPaintAttributeAccentColor teamPaintAttribute)
  putWord32Bits (teamPaintAttributePrimaryFinish teamPaintAttribute)
  putWord32Bits (teamPaintAttributeAccentFinish teamPaintAttribute)
