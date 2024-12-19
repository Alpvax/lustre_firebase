import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}
import lustre/effect
import lustre_firebase/firestore/value.{type Value}

import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import lustre_firebase.{type FirebaseApp} as _

pub type FirestoreInstance

pub type FirestoreError

pub type DocumentReferenceTag

pub type CollectionReferenceTag

pub type QueryReferenceTag

pub type DocumentReference(data) =
  FirestoreReference(DocumentReferenceTag, data)

pub type CollectionReference(data) =
  FirestoreReference(CollectionReferenceTag, data)

pub type FirestoreReference(kind, data)

pub type ReferenceError {
  EmptyPath(List(String))
  NotADoc(List(String))
  NotACollection(List(String))
}

@external(javascript, "../firestore.ffi.mjs", "debug")
pub fn debug(label: String, val: t) -> t

pub fn collection_str(
  instance: FirestoreInstance,
  path: String,
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  collection(instance, path, [], decoder, encoder)
}

pub fn collection_list(
  instance: FirestoreInstance,
  path: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  case path {
    [p, ..parts] -> collection(instance, p, parts, decoder, encoder)
    _ -> Error(EmptyPath(path))
  }
}

pub fn collection(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  case list.length(path_segments) % 2 {
    0 ->
      ext_collection(instance, path, path_segments, decoder, encoder)
      |> result.map_error(NotACollection)
    _ -> Error(NotACollection([path, ..path_segments]))
  }
}

@external(javascript, "../firestore.ffi.mjs", "collectionImpl")
fn ext_collection(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) -> Result(FirestoreReference(CollectionReferenceTag, data), List(String))

pub fn doc_ref_str(
  instance: FirestoreInstance,
  path: String,
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  doc(instance, path, [], decoder, encoder)
}

pub fn doc_ref_list(
  instance: FirestoreInstance,
  path: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  case path {
    [p, ..parts] -> doc(instance, p, parts, decoder, encoder)
    _ -> Error(EmptyPath(path))
  }
}

pub fn doc(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) {
  case list.length(path_segments) % 2 {
    1 ->
      ext_doc(instance, path, path_segments, decoder, encoder)
      |> result.map_error(NotADoc)
    _ -> Error(NotADoc([path, ..path_segments]))
  }
}

@external(javascript, "../firestore.ffi.mjs", "docImpl")
fn ext_doc(
  instance: FirestoreInstance,
  path: String,
  path_segments: List(String),
  decode decoder: Decoder(data),
  encode encoder: fn(data) -> Value,
) -> Result(FirestoreReference(DocumentReferenceTag, data), List(String))

@external(javascript, "../firestore.ffi.mjs", "withConverter")
pub fn with_converter(
  ref: FirestoreReference(t, a),
  decode decoder: Decoder(b),
  encode encoder: Option(fn(b) -> Value),
) -> FirestoreReference(t, b)

// pub fn id(ref: FirestoreReference(t, a)) -> String {
//   nel.last(ref.path)
// }

// pub fn path(ref: FirestoreReference(t, a)) -> nel.NonEmptyList(String) {
//   ref.path
// }

// pub fn path_list(ref: FirestoreReference(t, a)) -> List(String) {
//   nel.to_list(ref.path)
// }

// pub fn encode(ref: FirestoreReference(t, a), value: a) {
//   let _ = io.debug(#("Encoding:", value, " => ", ref.encoder(value)))
//   ref.encoder(value)
// }

// pub fn decode(ref: FirestoreReference(t, a), input: dynamic.Dynamic) {
//   ref.decoder(input)
// }

// fn concat_path(path_segments: List(String), additional: NonEmptyList(String)) {
//   concat_path_list(path_segments, nel.to_list(additional))
// }

// fn concat_path_list(path_segments: List(String), additional: List(String)) {
//   list.reverse(path_segments)
//   |> list.fold_right(from: additional, with: list.prepend)
// }

// pub fn relative_collection(
//   ref: FirestoreReference(t, a),
//   path: NonEmptyList(String),
//   decode decoder: Decoder(data),
//   encode encoder: fn(data) -> Value,
// ) {
//   collection(
//     ref.instance,
//     ref.path.first,
//     concat_path(ref.path.rest, path),
//     decoder,
//     encoder,
//   )
// }

// pub fn relative_doc(
//   ref: FirestoreReference(t, a),
//   path: NonEmptyList(String),
//   decode decoder: Decoder(data),
//   encode encoder: fn(data) -> Value,
// ) {
//   doc(
//     ref.instance,
//     ref.path.first,
//     concat_path(ref.path.rest, path),
//     decoder,
//     encoder,
//   )
// }

@external(javascript, "../firestore.ffi.mjs", "getFirestore")
pub fn get_instance(app: FirebaseApp) -> FirestoreInstance

pub fn add_doc(
  collection: CollectionReference(a),
  data: a,
  msg_converter: fn(DocumentReference(a)) -> msg,
) {
  effect.from(fn(dispatch) {
    ffi_add_doc(collection, data)
    |> promise.tap(dispatch)
    Nil
  })
  |> effect.map(msg_converter)
}

@external(javascript, "../firestore.ffi.mjs", "addDocImpl")
fn ffi_add_doc(
  collection: CollectionReference(a),
  data: a,
) -> Promise(DocumentReference(a))
// @external(javascript, "../firestore.ffi.mjs", "subscribeImpl")
// pub fn subscribe(query: reference.FirestoreReference(t, a)) -> fn() -> Nil
// @external(javascript, "../firestore.ffi.mjs", "collectionImpl")
// pub fn collection_ref_str(
//   instance: FirestoreInstance,
//   path: String,
// ) -> CollectionReference(a)

// @external(javascript, "../firestore.ffi.mjs", "collectionImpl")
// pub fn collection_ref(
//   instance: FirestoreInstance,
//   path: List(String),
// ) -> CollectionReference(a)

// pub fn with_collection_type(
//   ref: CollectionReference(a),
//   decode decoder: Decoder(b),
//   encode encoder: Option(fn(b) -> Dynamic),
// ) -> CollectionReference(b) {
//   ColRefTyped(ref.path, decoder, option.unwrap(encoder, dynamic.from))
// }
