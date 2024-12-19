import gleam/dynamic.{type Decoder, type Dynamic}
import gleam/list
import gleam/option.{type Option}
import lustre_firebase/firestore.{type FirestoreInstance} as _
import non_empty_list.{type NonEmptyList} as nel

pub type DocumentReferenceTag

pub type DocumentReference(data) =
  QueryReference(DocumentReferenceTag, data)

pub type CollectionReferenceTag

pub type CollectionReference(data) =
  QueryReference(CollectionReferenceTag, data)

pub type RefInternal(kind)

pub opaque type QueryReference(kind, data) {
  QueryReference(
    internal: RefInternal(kind),
    firestore: FirestoreInstance,
    path: NonEmptyList(String),
    decoder: Decoder(data),
    encoder: fn(data) -> Dynamic,
  )
}

pub type ReferenceError {
  EmptyPath(List(String))
  NotADoc(List(String))
  NotACollection(List(String))
}

pub fn collection_ref_str(instance: FirestoreInstance, path: String) {
  collection(instance, path, [])
}

pub fn collection_ref_list(instance: FirestoreInstance, path: List(String)) {
  case path {
    [p, ..parts] -> collection(instance, p, parts)
    _ -> Error(EmptyPath(path))
  }
}

pub fn collection(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
) {
  case list.length(path_segments) % 2 {
    0 -> {
      let internal = ext_collection(instance, path, path_segments)
      Ok(QueryReference(
        internal,
        instance,
        nel.new(path, path_segments),
        dynamic.dynamic,
        dynamic.from,
      ))
    }
    _ -> Error(NotACollection([path, ..path_segments]))
  }
}

@external(javascript, "../../firestore.ffi.mjs", "collectionImpl")
fn ext_collection(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
) -> RefInternal(CollectionReferenceTag)

pub fn doc_ref_str(instance: FirestoreInstance, path: String) {
  doc(instance, path, [])
}

pub fn doc_ref_list(instance: FirestoreInstance, path: List(String)) {
  case path {
    [p, ..parts] -> doc(instance, p, parts)
    _ -> Error(EmptyPath(path))
  }
}

pub fn doc(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
) {
  case list.length(path_segments) % 2 {
    1 -> {
      let internal = ext_doc(instance, path, path_segments)
      Ok(QueryReference(
        internal,
        instance,
        nel.new(path, path_segments),
        dynamic.dynamic,
        dynamic.from,
      ))
    }
    _ -> Error(NotADoc([path, ..path_segments]))
  }
}

@external(javascript, "../../firestore.ffi.mjs", "docImpl")
fn ext_doc(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
) -> RefInternal(DocumentReferenceTag)

pub fn with_converter(
  ref: QueryReference(t, a),
  decode decoder: Decoder(b),
  encode encoder: Option(fn(b) -> Dynamic),
) -> QueryReference(t, b) {
  QueryReference(
    ref.internal,
    ref.firestore,
    ref.path,
    decoder,
    option.unwrap(encoder, dynamic.from),
  )
}

pub fn id(ref: QueryReference(t, a)) -> String {
  nel.last(ref.path)
}

pub fn path(ref: QueryReference(t, a)) -> nel.NonEmptyList(String) {
  ref.path
}

pub fn path_list(ref: QueryReference(t, a)) -> List(String) {
  nel.to_list(ref.path)
}

pub fn encode(ref: QueryReference(t, a), value: a) {
  ref.encoder(value)
}

pub fn decode(ref: QueryReference(t, a), input: Dynamic) {
  ref.decoder(input)
}
