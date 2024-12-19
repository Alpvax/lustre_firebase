import gleam/dynamic
import gleam/option.{type Option}
import lustre_firebase/firestore.{type DocumentReference}

pub type DocumentSnapshot(kind, a)

pub type QueryDocumentSnapshot(a) =
  DocumentSnapshot(firestore.QueryReferenceTag, a)

pub type QuerySnapshot(a)

pub type Query(a)

pub type SnapshotMetadata

pub type SnapshotListenOptions {
  SnapshotListenOptions(
    /// Include a change even if only the metadata of the query or of a document
    /// changed. Default is false.
    include_metadata_changes: Bool,
    /// By default (False), listens to both cache and server.
    /// Setting it to True ignores the server.
    /// Internally uses `source: "default" | "cache"`
    cached_only: Bool,
  )
}

pub type DocumentChange(a) {
  Added(doc: QueryDocumentSnapshot(a), new_index: Int)
  Modified(doc: QueryDocumentSnapshot(a), old_index: Int, new_index: Int)
  Removed(doc: QueryDocumentSnapshot(a), old_index: Int)
}

@external(javascript, "../../firestore.ffi.mjs", "docExists")
pub fn exists(doc: DocumentSnapshot(kind, a)) -> Bool

@external(javascript, "../../firestore.ffi.mjs", "docId")
pub fn doc_id(doc: DocumentSnapshot(kind, a)) -> String

@external(javascript, "../../firestore.ffi.mjs", "docRef")
pub fn doc_ref(doc: DocumentSnapshot(kind, a)) -> DocumentReference(a)

@external(javascript, "../../firestore.ffi.mjs", "getDataOpt")
pub fn get_optional_data(
  doc: DocumentSnapshot(kind, a),
) -> Option(Result(a, dynamic.DecodeError))

@external(javascript, "../../firestore.ffi.mjs", "getData")
pub fn get_data(doc: QueryDocumentSnapshot(a)) -> Result(a, dynamic.DecodeError)

@external(javascript, "../../firestore.ffi.mjs", "getMetadata")
pub fn doc_metadata(doc: DocumentSnapshot(kind, a)) -> SnapshotMetadata

/// True if the snapshot contains the result of local writes (for example
/// `set()` or `update()` calls) that have not yet been committed to the
/// backend. If your listener has opted into metadata updates (via
/// `SnapshotListenOptions`) you will receive another snapshot with
/// `hasPendingWrites` equal to false once the writes have been committed to
/// the backend.
@external(javascript, "../../firestore.ffi.mjs", "hasPendingWrites")
pub fn has_pending_writes(metadata: SnapshotMetadata) -> Bool

/// True if the snapshot was created from cached data rather than guaranteed
/// up-to-date server data. If your listener has opted into metadata updates
/// (via `SnapshotListenOptions`) you will receive another snapshot with
/// `fromCache` set to false once the client has received up-to-date data from
/// the backend.
@external(javascript, "../../firestore.ffi.mjs", "isFromCache")
pub fn is_from_cache(metadata: SnapshotMetadata) -> Bool

/// Metadata about this snapshot, concerning its source and if it has local
/// modifications.
@external(javascript, "../../firestore.ffi.mjs", "getMetadata")
pub fn query_metadata(query: QuerySnapshot(a)) -> SnapshotMetadata

/// The query on which you called `get` or `onSnapshot` in order to get this
/// `QuerySnapshot`.
@external(javascript, "../../firestore.ffi.mjs", "getSnapshotQuery")
pub fn get_query(snapshot: QuerySnapshot(a)) -> Query(a)

/// An array of all the documents in the `QuerySnapshot`.
@external(javascript, "../../firestore.ffi.mjs", "getQueryDocs")
pub fn get_docs(snapshot: QuerySnapshot(a)) -> List(QueryDocumentSnapshot(a))

/// The number of documents in the `QuerySnapshot`.
@external(javascript, "../../firestore.ffi.mjs", "getDocCount")
pub fn get_count(snapshot: QuerySnapshot(a)) -> Int

/// True if there are no documents in the `QuerySnapshot`.
@external(javascript, "../../firestore.ffi.mjs", "isEmpty")
pub fn is_empty(snapshot: QuerySnapshot(a)) -> Bool

/// Enumerates all of the documents in the `QuerySnapshot`.
///
/// @param callback - A callback to be called with a `QueryDocumentSnapshot` for
/// each document in the snapshot.
/// @param thisArg - The `this` binding for the callback.
@external(javascript, "../../firestore.ffi.mjs", "queryEach")
pub fn for_each(
  snapshot: QuerySnapshot(a),
  callback: fn(QueryDocumentSnapshot(a)) -> Nil,
) -> Nil

/// Returns an array of the documents changes since the last snapshot. If this
/// is the first snapshot, all documents will be in the list as 'added'
/// changes.
@external(javascript, "../../firestore.ffi.mjs", "queryChanges")
pub fn doc_changes(snapshot: QuerySnapshot(a)) -> List(DocumentChange(a))

/// Returns an array of the documents changes since the last snapshot. If this
/// is the first snapshot, all documents will be in the list as 'added'
/// changes.
///
/// @param options - `SnapshotListenOptions` that control whether metadata-only
/// changes (i.e. only `DocumentSnapshot.metadata` changed) should trigger
/// snapshot events.
@external(javascript, "../../firestore.ffi.mjs", "queryChanges")
pub fn doc_changes_with_options(
  snapshot: QuerySnapshot(a),
  options: SnapshotListenOptions,
) -> List(DocumentChange(a))
