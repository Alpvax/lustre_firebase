import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import lustre_firebase/firestore.{type FirestoreReference}
import lustre_firebase/firestore/snapshot.{type SnapshotListenOptions}

pub type Unsubscribe =
  fn() -> Nil

pub type FirestoreSubscriptionHandler(a, msg) =
  fn(SubscriptionEvent(a)) -> Option(msg)

pub type SubscriptionEvent(a) {
  Subscribed(Unsubscribe)
  Unsubscribed
  Changed(snapshot.DocumentChange(a))
  FirestoreError(firestore.FirestoreError)
}

pub fn subscribe_query(
  query: FirestoreReference(t, a),
  handle: FirestoreSubscriptionHandler(a, msg),
) {
  do_subscribe(query, None, handle)
}

pub fn subscribe_query_with_options(
  query: FirestoreReference(t, a),
  options: SnapshotListenOptions,
  handle: FirestoreSubscriptionHandler(a, msg),
) {
  do_subscribe(query, Some(options), handle)
}

pub fn subscribe_doc(
  query: firestore.DocumentReference(a),
  handle: FirestoreSubscriptionHandler(a, msg),
) {
  do_subscribe(query, None, handle)
}

pub fn subscribe_doc_with_options(
  query: FirestoreReference(t, a),
  options: SnapshotListenOptions,
  handle: FirestoreSubscriptionHandler(a, msg),
) {
  do_subscribe(query, Some(options), handle)
}

fn do_subscribe(
  query: FirestoreReference(t, a),
  options: Option(SnapshotListenOptions),
  handle: FirestoreSubscriptionHandler(a, msg),
) -> Effect(msg) {
  effect.from(fn(dispatch) {
    let do_handle = fn(evt: SubscriptionEvent(a)) {
      case handle(evt) {
        Some(msg) -> dispatch(msg)
        None -> Nil
      }
    }
    let unsubscribe =
      do_subscribe_internal(
        query,
        options,
        fn(e) { do_handle(FirestoreError(e)) },
        fn(change) { do_handle(Changed(change)) },
      )
    do_handle(
      Subscribed(fn() {
        let _ = unsubscribe()
        do_handle(Unsubscribed)
      }),
    )
  })
}

@external(javascript, "../../firestore.ffi.mjs", "subscribe")
fn do_subscribe_internal(
  query: FirestoreReference(t, a),
  options: Option(SnapshotListenOptions),
  on_error: fn(firestore.FirestoreError) -> Nil,
  on_change: fn(snapshot.DocumentChange(a)) -> Nil,
) -> Unsubscribe
