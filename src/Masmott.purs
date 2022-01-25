module Masmott
  ( SelectViewSpec
  , ViewSpecs
  , a
  , main
  , onViewSrcCreated
  , onViewSrcCreatedTrigger
  )
  where

import Prelude

import Control.Parallel (parSequence)
import Data.FunctorWithIndex (mapWithIndex)
import Data.List (List)
import Data.Map (Map)
import Data.Map as M
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Console as Console
import Firebase.Admin.Firestore (CollectionPath(..), CreateDocResult, DocData, DocFieldName(..), DocId(..), createDoc)
import Firebase.Admin.Firestore as FAF
import Firebase.Functions.Firestore (CloudFunction, TriggerCtx)
import Trigger (CollectionName(..), ViewName(..), makeViewCollectionPath, onCreate)

type SelectViewSpec
  = Map DocFieldName Unit

type ViewSpecs
  = Map ViewName SelectViewSpec

materializeSelectView :: SelectViewSpec -> DocData -> DocData
materializeSelectView spec = M.filterKeys $ flip M.member spec

createView :: CollectionName -> TriggerCtx -> ViewName -> SelectViewSpec -> Aff CreateDocResult
createView collectionName ctx viewName viewSpec = FAF.createDoc collectionPath docId docData
  where
  collectionPath = (makeViewCollectionPath collectionName (Just viewName))

  docId = ctx.id

  docData = (materializeSelectView viewSpec ctx.docData)

onViewSrcCreated :: ViewSpecs -> CollectionName -> Maybe ViewName -> TriggerCtx -> Aff (List CreateDocResult)
onViewSrcCreated viewSpecs collectionName _ ctx =
  viewSpecs
    # mapWithIndex (createView collectionName ctx)
    # M.values
    # parSequence

onViewSrcCreatedTrigger :: ViewSpecs -> CollectionName -> Maybe ViewName -> CloudFunction
onViewSrcCreatedTrigger viewSpecs collectionName viewName = onCreate collectionName viewName handler
  where
  handler = onViewSrcCreated viewSpecs collectionName viewName

fooViewSpecs :: ViewSpecs
fooViewSpecs =
  M.fromFoldable
    [ Tuple (ViewName "page")
        $ M.fromFoldable
            [ Tuple (DocFieldName "a") unit
            , Tuple (DocFieldName "b") unit
            ]
    , Tuple (ViewName "card")
        $ M.fromFoldable
            [ Tuple (DocFieldName "a") unit
            ]
    ]

a :: CloudFunction
a = onViewSrcCreatedTrigger fooViewSpecs (CollectionName "user") Nothing

main :: Effect Unit
main = do
  Console.log "START"
  launchAff_ $ createDoc (CollectionPath "a") (DocId "b") (M.fromFoldable [ Tuple (DocFieldName "x") "y" ])
  Console.log "END"
