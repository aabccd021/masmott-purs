module Firebase.Admin.Firestore
  ( CollectionPath(..)
  , CreateDocResult
  , DocData
  , DocData_
  , DocFieldName(..)
  , DocId(..)
  , DocSnapshot
  , FirebaseError(..)
  , Timestamp
  , createDoc
  , getDoc
  )
  where

import Prelude

import Control.Promise (Promise, toAff)
import Data.Either (Either(..))
import Data.Map (Map)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)

newtype DocFieldName
  = DocFieldName String

derive newtype instance eqDocFieldName :: Eq DocFieldName

derive newtype instance ordDocFieldName :: Ord DocFieldName

type DocData
  = Map DocFieldName String

type DocData_
  = Map String String

newtype DocId
  = DocId String

newtype CollectionPath
  = CollectionPath String

type DocSnapshot
  = { id :: DocId
    , docData :: DocData
    }

type DocSnapshot_ 
  = { docData :: DocData_
    , createTime :: Timestamp
    , updateTime :: Timestamp
    , readTime :: Timestamp
    }

type Timestamp
  = { seconds :: Int
    , nanoseconds :: Int
    }

newtype FirebaseError
  = FirebaseError String

type CreateDocResult_ = Either String Timestamp

foreign import _createDoc :: 
  (String -> CreateDocResult_) -> 
  (Timestamp -> CreateDocResult_) -> 
  String -> 
  String -> 
  DocData -> 
  Promise CreateDocResult_

wrapCreateDocResult :: CreateDocResult_ -> CreateDocResult
wrapCreateDocResult (Left l) = Left $ FirebaseError l
wrapCreateDocResult (Right r) = Right r

type CreateDocResult = Either FirebaseError Timestamp

createDoc :: CollectionPath -> DocId -> DocData -> Aff CreateDocResult
createDoc (CollectionPath collectionPath) (DocId docId) docData = 
  _createDoc Left Right collectionPath docId docData
    # toAff 
    # map wrapCreateDocResult

type GetDocResult_ = Either String (Maybe DocData_)

foreign import _getDoc :: 
  (String -> GetDocResult_) -> 
  (Maybe DocData_ -> GetDocResult_) -> 
  Maybe DocData_ -> 
  (DocData_ -> Maybe DocData_) -> 
  String -> 
  String -> 
  Promise GetDocResult_

getDoc :: CollectionPath -> DocId -> Aff GetDocResult_
getDoc (CollectionPath collectionPath) (DocId docId) = 
  _getDoc Left Right Nothing Just collectionPath docId # toAff
