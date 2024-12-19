import gleam/dynamic
import gleam/io
import gleam/option
import gleeunit
import gleeunit/should
import lustre_firebase as firebase
import lustre_firebase/firestore
import lustre_firebase/firestore/subscribe
import lustre_firebase/firestore/value

pub fn main() {
  let _ =
    firebase.config("dummy-2fc35")
    |> firebase.with_api_key("AIzaSyCjE7jdCCRmic5uPyBytBt6xGIHfKtAr-k")
    |> firebase.with_auth_domain("dummy-2fc35.firebaseapp.com")
    |> firebase.with_storage_bucket("dummy-2fc35.firebasestorage.app")
    |> firebase.with_messaging_sender_id("120715523473")
    |> firebase.with_app_id("1:120715523473:web:9c9d880bc0023a32c01630")
    |> firebase.initialize_app
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn subscribe_test() {
  let app = firebase.get_app()
  let db = firestore.get_instance(app)
  case firestore.collection_str(db, "foo", dynamic.dynamic, value.DBUnknown) {
    Ok(ref) -> {
      {
        use event <- subscribe.subscribe_query(ref)
        case event {
          subscribe.Changed(change) -> {
            io.debug(change)
            option.None
          }
          _ -> {
            io.debug(event)
            option.None
          }
        }
      }
      |> io.debug
      Nil
    }
    Error(e) -> {
      io.debug(e)
      Nil
    }
  }
}
// pub fn collection_ref_test() {
//   let app = app.get_app()
//   let db = firestore.get_instance(app)
//   reference.collection_str(db, "foo", dynamic.dynamic, function.identity)
// }

// pub fn add_doc_test() {
//   let app = app.get_app()
//   let db = firestore.get_instance(app)
//   let ref =
//     should.be_ok(reference.collection_str(
//       db,
//       "foo",
//       dynamic.dict(dynamic.string, dynamic.string),
//       function.identity,
//     ))
//     |> firestore.add_doc(dict.from_list([#("foo", "bar")]))
//   io.print("Resolving:")
//   io.debug(ref)
//   promise.tap(ref, io.debug)
// }
