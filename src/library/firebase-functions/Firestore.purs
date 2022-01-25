module Firebase.Functions.Firestore
  ( CloudFunction
  , DocumentBuilder
  , EventContext
  , OnCreateTriggerHandler
  , TriggerCtx
  , document
  , onCreate
  )
  where

import Prelude
import Aviary.Birds ((...))
import Control.Promise (Promise, fromAff)
import Data.List (List)
import Data.Map (Map)
import Data.Map as M
import Data.Tuple (Tuple)
import Data.Tuple as T
import Effect (Effect)
import Effect.Aff (Aff)
import Firebase.Admin.Firestore (CollectionPath(..), DocData, DocData_, DocFieldName(..), DocId(..))

newtype DocumentBuilder
  = DocumentBuilder Unit

newtype CloudFunction
  = CloudFunction Unit

type EventContext
  = Unit

type TriggerCtx
  = { id :: DocId
    , docData :: DocData
    , event :: EventContext
    }

type OnCreateTriggerHandler a
  = (TriggerCtx -> Aff a)

type OnCreateTriggerHandler_ a
  = (TriggerCtx_ -> Effect (Promise a))

type TriggerCtx_
  = { id :: String
    , docData :: DocData_
    , event :: EventContext
    }

foreign import _document :: String -> DocumentBuilder

document :: CollectionPath -> DocumentBuilder
document (CollectionPath collectionPath) = _document collectionPath

foreign import _onCreate :: forall a. DocumentBuilder -> OnCreateTriggerHandler_ a -> CloudFunction

mapSnd :: forall a b c. (a -> b) -> Tuple a c -> Tuple b c
mapSnd f = T.swap >>> map f >>> T.swap

wrapDocDataEntry :: Tuple String String -> Tuple DocFieldName String
wrapDocDataEntry = mapSnd DocFieldName

toList :: forall k v. Map k v -> List (Tuple k v)
toList = M.toUnfoldable

wrapDocData :: DocData_ -> DocData
wrapDocData = toList >>> map wrapDocDataEntry >>> M.fromFoldable

wrapTriggerCtx :: TriggerCtx_ -> TriggerCtx
wrapTriggerCtx { id, docData, event } = { id: DocId id, docData: wrapDocData docData, event }

wrapHandler :: forall c. OnCreateTriggerHandler c -> TriggerCtx_ -> Aff c
wrapHandler handler triggerCtx = handler $ wrapTriggerCtx triggerCtx

onCreateFromCollectionPath :: forall a. CollectionPath -> OnCreateTriggerHandler_ a -> CloudFunction
onCreateFromCollectionPath (CollectionPath collectionPath) = _onCreate $ _document collectionPath

onCreate :: forall c. CollectionPath -> OnCreateTriggerHandler c -> CloudFunction
onCreate collectionPath = onCreateFromCollectionPath collectionPath <<< fromAff ... wrapHandler
