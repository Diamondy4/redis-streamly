module Database.Redis.Streams.Stream where

import Control.Monad.Except
import Control.Monad.State
import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as Ch8
import Data.Coerce
import Database.Redis (Redis, Reply, StreamsRecord (..), XReadOpts)
import Database.Redis qualified as Redis
import Database.Redis.Streams.SpecialMessageID
import Database.Redis.Streams.Types
import Database.Redis.Streams.Types.Error

sendUpstream ::
    StreamKey ->
    Entry ->
    Redis (Either RedisStreamSomeError ByteString)
sendUpstream key entries =
    runExceptT
        . withExceptT replyToRedisStreamSomeError
        . ExceptT
        $ Redis.xadd (coerce key) (coerce autogenMessageID) (coerce entries)

{- | Read next message from stream.

 Producer for your favorite streaming library. Use returned 'MessageID' for next iterations.
-}
readStream ::
    StreamKey -> MessageID -> XReadOpts -> Redis (Either RedisStreamSomeError (MessageID, [StreamsRecord]))
readStream key lstMsgId readOpts = do
    res <-
        Redis.xreadOpts @Redis
            [(coerce key, coerce lstMsgId)]
            readOpts
    pure $ case res of
        (Left err) -> Left $ replyToRedisStreamSomeError err
        -- Will be one response as only one stream is read
        Right (Just responses) ->
            let (records, newLstMsgId) =
                    (`runState` lstMsgId)
                        . traverse (\record -> record <$ put (MessageID $ Redis.recordId record))
                        $ Redis.records =<< responses
             in Right (newLstMsgId, records)
        Right Nothing -> Right (lstMsgId, [])