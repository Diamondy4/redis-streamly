module Database.Redis.Store.Streams.Stream.Serialize where

import Data.ByteString
import Data.Store
import Database.Redis
import Database.Redis.Store.Streams.Common
import Database.Redis.Streams.Stream qualified as SRedis
import Database.Redis.Streams.Types
import Database.Redis.Streams.Types.Error (RedisStreamSomeError)

-- | Serialize with store and send some data using Redis stream.
sendUpstream ::
    (Store a) =>
    StreamKey ->
    a ->
    Redis (Either RedisStreamSomeError ByteString)
sendUpstream key x = SRedis.sendUpstream key (toStoreEntry x)