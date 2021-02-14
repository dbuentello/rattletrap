{-# LANGUAGE TemplateHaskell #-}

module Rattletrap.Type.Content where

import qualified Rattletrap.Type.Cache as Cache
import qualified Rattletrap.Type.ClassMapping as ClassMapping
import Rattletrap.Type.Common
import qualified Rattletrap.Type.Frame as Frame
import qualified Rattletrap.Type.KeyFrame as KeyFrame
import qualified Rattletrap.Type.List as List
import qualified Rattletrap.Type.Mark as Mark
import qualified Rattletrap.Type.Message as Message
import qualified Rattletrap.Type.Str as Str
import qualified Rattletrap.Type.U32 as U32
import Rattletrap.Utility.Bytes
import Rattletrap.Decode.Common
import Rattletrap.Encode.Common
import qualified Rattletrap.Type.ClassAttributeMap as ClassAttributeMap

import qualified Control.Monad.Trans.State as State
import qualified Data.Binary.Get as Binary
import qualified Data.Binary as Binary
import qualified Data.Binary.Bits.Put as BinaryBits
import qualified Data.Binary.Put as Binary
import qualified Data.ByteString as Bytes
import qualified Data.ByteString.Lazy as LazyBytes

-- | Contains low-level game data about a 'Rattletrap.Replay.Replay'.
data Content = Content
  { levels :: List.List Str.Str
  -- ^ This typically only has one element, like @stadium_oob_audio_map@.
  , keyFrames :: List.List KeyFrame.KeyFrame
  -- ^ A list of which frames are key frames. Although they aren't necessary
  -- for replay, key frames are frames that replicate every actor. They
  -- typically happen once every 10 seconds.
  , streamSize :: U32.U32
  -- ^ The size of the stream in bytes. This is only really necessary because
  -- the stream has some arbitrary amount of padding at the end.
  , frames :: [Frame.Frame]
  -- ^ The actual game data. This is where all the interesting information is.
  , messages :: List.List Message.Message
  -- ^ Debugging messages. In newer replays, this is always empty.
  , marks :: List.List Mark.Mark
  -- ^ Tick marks shown on the scrubber when watching a replay.
  , packages :: List.List Str.Str
  -- ^ A list of @.upk@ files to load, like
  -- @..\\..\\TAGame\\CookedPCConsole\\Stadium_P.upk@.
  , objects :: List.List Str.Str
  -- ^ Objects in the stream. Used for the
  -- 'Rattletrap.Type.ClassAttributeMap.ClassAttributeMap'.
  , names :: List.List Str.Str
  -- ^ It's not clear what these are used for. This list is usually not empty,
  -- but appears unused otherwise.
  , classMappings :: List.List ClassMapping.ClassMapping
  -- ^ A mapping between classes and their ID in the stream. Used for the
  -- 'Rattletrap.Type.ClassAttributeMap.ClassAttributeMap'.
  , caches :: List.List Cache.Cache
  -- ^ A list of classes along with their parent classes and attributes. Used
  -- for the 'Rattletrap.Type.ClassAttributeMap.ClassAttributeMap'.
  , unknown :: [Word8]
  }
  deriving (Eq, Show)

$(deriveJson ''Content)

empty :: Content
empty = Content
  { levels = List.empty
  , keyFrames = List.empty
  , streamSize = U32.fromWord32 0
  , frames = []
  , messages = List.empty
  , marks = List.empty
  , packages = List.empty
  , objects = List.empty
  , names = List.empty
  , classMappings = List.empty
  , caches = List.empty
  , unknown = []
  }

bytePut :: Content -> BytePut
bytePut content = do
  List.bytePut Str.bytePut (levels content)
  List.bytePut KeyFrame.bytePut (keyFrames content)
  let
    stream = LazyBytes.toStrict
      (Binary.runPut (BinaryBits.runBitPut (Frame.putFrames (frames content)))
      )
    -- This is a little strange. When parsing a binary replay, the stream size
    -- is given before the stream itself. When generating the JSON, the stream
    -- size is included. That allows a bit-for-bit identical binary replay to
    -- be generated from the JSON. However if you modify the JSON before
    -- converting it back into binary, the stream size might be different.
    --
    -- If it was possible to know how much padding the stream required without
    -- carrying it along as extra data on the side, this logic could go away.
    -- Unforunately that isn't currently known. See this issue for details:
    -- <https://github.com/tfausak/rattletrap/issues/171>.
    expectedStreamSize = streamSize content
    actualStreamSize = U32.fromWord32 . fromIntegral $ Bytes.length stream
    streamSize_ = U32.fromWord32 $ max
      (U32.toWord32 expectedStreamSize)
      (U32.toWord32 actualStreamSize)
  U32.bytePut streamSize_
  Binary.putByteString
    (reverseBytes (padBytes (U32.toWord32 streamSize_) stream))
  List.bytePut Message.bytePut (messages content)
  List.bytePut Mark.bytePut (marks content)
  List.bytePut Str.bytePut (packages content)
  List.bytePut Str.bytePut (objects content)
  List.bytePut Str.bytePut (names content)
  List.bytePut ClassMapping.bytePut (classMappings content)
  List.bytePut Cache.bytePut (caches content)
  mapM_ Binary.putWord8 (unknown content)

byteGet
  :: (Int, Int, Int)
  -- ^ Version numbers, usually from 'Rattletrap.Header.getVersion'.
  -> Int
  -- ^ The number of frames in the stream, usually from
  -- 'Rattletrap.Header.getNumFrames'.
  -> Word
  -- ^ The maximum number of channels in the stream, usually from
  -- 'Rattletrap.Header.getMaxChannels'.
  -> ByteGet Content
byteGet version numFrames maxChannels = do
  (levels_, keyFrames_, streamSize_) <-
    (,,)
    <$> List.byteGet Str.byteGet
    <*> List.byteGet KeyFrame.byteGet
    <*> U32.byteGet
  (stream, messages_, marks_, packages_, objects_, names_, classMappings_, caches_) <-
    (,,,,,,,)
    <$> getByteString (fromIntegral (U32.toWord32 streamSize_))
    <*> List.byteGet Message.byteGet
    <*> List.byteGet Mark.byteGet
    <*> List.byteGet Str.byteGet
    <*> List.byteGet Str.byteGet
    <*> List.byteGet Str.byteGet
    <*> List.byteGet ClassMapping.byteGet
    <*> List.byteGet Cache.byteGet
  let
    classAttributeMap =
      ClassAttributeMap.make objects_ classMappings_ caches_ names_
    bitGet = State.evalStateT
      (Frame.decodeFramesBits version numFrames maxChannels classAttributeMap)
      mempty
  frames_ <- either fail pure (runDecodeBits bitGet (reverseBytes stream))
  Content
      levels_
      keyFrames_
      streamSize_
      frames_
      messages_
      marks_
      packages_
      objects_
      names_
      classMappings_
      caches_
    . LazyBytes.unpack
    <$> Binary.getRemainingLazyByteString
