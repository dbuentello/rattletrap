{-# LANGUAGE TemplateHaskell #-}

module Rattletrap.Type.RemoteId where

import qualified Rattletrap.BitGet as BitGet
import qualified Rattletrap.BitPut as BitPut
import Rattletrap.Type.Common
import qualified Rattletrap.Type.Str as Str
import qualified Rattletrap.Type.U64 as U64
import qualified Rattletrap.Type.U8 as U8
import Rattletrap.Utility.Bytes

import qualified Data.ByteString as Bytes
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Text
import qualified Data.Word as Word

data RemoteId
  = PlayStation Text [Word8]
  | PsyNet (Either U64.U64 (U64.U64, U64.U64, U64.U64, U64.U64))
  | Splitscreen Word32
  -- ^ Really only 24 bits.
  | Steam U64.U64
  | Switch U64.U64 U64.U64 U64.U64 U64.U64
  | Xbox U64.U64
  | Epic Str.Str
  deriving (Eq, Show)

$(deriveJson ''RemoteId)

bitPut :: RemoteId -> BitPut.BitPut
bitPut remoteId = case remoteId of
  PlayStation name bytes ->
    let rawName = reverseBytes (padBytes (16 :: Int) (encodeLatin1 name))
    in BitPut.byteString rawName <> BitPut.byteString (Bytes.pack bytes)
  PsyNet e -> case e of
    Left l -> U64.bitPut l
    Right (a, b, c, d) -> putWord256 a b c d
  Splitscreen word24 -> BitPut.bits 24 word24
  Steam word64 -> U64.bitPut word64
  Switch a b c d -> putWord256 a b c d
  Xbox word64 -> U64.bitPut word64
  Epic str -> Str.bitPut str

putWord256 :: U64.U64 -> U64.U64 -> U64.U64 -> U64.U64 -> BitPut.BitPut
putWord256 a b c d =
  U64.bitPut a <> U64.bitPut b <> U64.bitPut c <> U64.bitPut d

bitGet :: (Int, Int, Int) -> U8.U8 -> BitGet.BitGet RemoteId
bitGet version systemId = case U8.toWord8 systemId of
  0 -> Splitscreen <$> BitGet.bits 24
  1 -> Steam <$> U64.bitGet
  2 -> PlayStation <$> decodePsName <*> decodePsBytes version
  4 -> Xbox <$> U64.bitGet
  6 -> do
    (a, b, c, d) <- getWord256
    pure $ Switch a b c d
  7 -> if version >= (868, 24, 10)
    then PsyNet . Left <$> U64.bitGet
    else PsyNet . Right <$> getWord256
  11 -> Epic <$> Str.bitGet
  _ -> fail ("[RT09] unknown system id " <> show systemId)

decodePsName :: BitGet.BitGet Text.Text
decodePsName = fmap
  (Text.dropWhileEnd (== '\x00') . Text.decodeLatin1 . reverseBytes)
  (BitGet.byteString 16)

decodePsBytes :: (Int, Int, Int) -> BitGet.BitGet [Word.Word8]
decodePsBytes version = Bytes.unpack
  <$> BitGet.byteString (if version >= (868, 20, 1) then 24 else 16)

getWord256 :: BitGet.BitGet (U64.U64, U64.U64, U64.U64, U64.U64)
getWord256 = do
  a <- U64.bitGet
  b <- U64.bitGet
  c <- U64.bitGet
  d <- U64.bitGet
  pure (a, b, c, d)
