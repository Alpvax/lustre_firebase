import { Result, Error, Ok, List } from "./gleam.mjs"
import { unwrap, is_none, Some, None } from "../gleam_stdlib/gleam/option.mjs";
import { unwrap_error } from "../gleam_stdlib/gleam/result.mjs";
import Dict from "../gleam_stdlib/dict.mjs";
import { from_unix_micro } from "../birl/birl.mjs";
import * as dbtypes from "./lustre_firebase/firestore/value.mjs"
import { Added, Modified, Removed } from "./lustre_firebase/firestore/snapshot.mjs"
import {
  addDoc, onSnapshot, collection, CollectionReference, doc, DocumentReference,
  getFirestore as getFirestoreInternal, Firestore, Timestamp, FirestoreError,
  arrayRemove, arrayUnion, deleteField, increment, serverTimestamp,
  DocumentSnapshot, QueryDocumentSnapshot, SnapshotMetadata, QuerySnapshot,
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js"
// } from "firebase/firestore";

export const getFirestore = getFirestoreInternal;

export const debug = (text, error) => {
  console.log(text, error);
  return error;
}

// =============== Value / Reference ================


export const fromBirlTime = (birlTime) => {
  const microsecs = birlTime.wall_time + birlTime.offset;
  return new Timestamp(Math.floor(microsecs / 1_000_000), (microsecs % 1_000_000) * 1000);
}
/**
 * 
 * @param {Timestamp} timestamp 
 * @returns 
 */
export const toBirlTime = (timestamp) => from_unix_micro(timestamp.seconds * 1_000_000 + Math.trunc(timestamp.nanoseconds / 1000));
export const now = () => Timestamp.now()

export const valueToString = (value) => JSON.stringify(encodeValue(value))


const encodeValue = (value, fieldPath = []) => {
  if (value instanceof dbtypes.DBArray) {
    return value[0].toArray().map((item, idx) => encodeValue(item, [...fieldPath, `listIndex:${idx}`]));
  } else if (value instanceof dbtypes.DBBool
    || value instanceof dbtypes.DBFloat || value instanceof dbtypes.DBInt
    || value instanceof dbtypes.DBString || value instanceof dbtypes.DBUnknown) {
    return value[0];
  } else if (value instanceof dbtypes.DBBytes) {
    console.warn("Saving `bytes` to db not currently implemented", { fieldPath, value });
  } else if (value instanceof dbtypes.DBDateTime) {
    return Timestamp.fromDate(new Date(value[0]))
  } else if (value instanceof dbtypes.DBGeo) {
    console.warn("Saving `Lat/Long` to db not currently implemented", { fieldPath, value });
  } else if (value instanceof dbtypes.DBMap) {
    // Dict
    return value[0].entries().reduce((acc, [k, v]) => Object.assign(acc, { [k]: encodeValue(v, [...fieldPath, k]) }), {});
  } else if (value instanceof dbtypes.DBNaN) {
    return NaN;
  } else if (value instanceof dbtypes.DBNull) {
    return null;
  } else if (value instanceof dbtypes.DBReference) {
    console.warn("Saving `Reference` to db not currently implemented", { fieldPath, value });
  } else if (value instanceof dbtypes.DBVector) {
    console.warn("Saving `Vector` to db not currently implemented", { fieldPath, value });
  } else if (value instanceof dbtypes.ArrayRemove) {
    return arrayRemove();
  } else if (value instanceof dbtypes.ArrayUnion) {
    return arrayUnion();
  } else if (value instanceof dbtypes.DeleteField) {
    return deleteField();
  } else if (value instanceof dbtypes.IncrementInt || value instanceof dbtypes.IncrementFloat) {
    return increment(value[0]);
  } else if (value instanceof dbtypes.ServerTimestamp) {
    return serverTimestamp();
  } else {
    console.error("Error occurred when encoding data for doc!", { fieldPath, input: modelObject, encoded: value, toFirestoreOptions: _options });
    throw new Error("Error occurred when encoding data for doc!");
  }
}
/**
 * @param {(dbData: Dynamic) => Result<T, List<DecodeError>>} decoder the function used to convert the data from the database to the correct gleam type
 * @param {(data: T) => any} encoder the function used to convert the app data type to the type to be saved in the database
 * @returns {import("firebase/firestore").FirestoreDataConverter}
 */
const converter = (decoder, encoder) => {
  const _decode_gleam_type = (snapshot, _options) => {
    const data = snapshot.data();
    const decoded = decoder(data);
    if (!Result.isResult(decoded)) {
      console.error("Error occurred when decoding doc! Not a result", { docId: snapshot.id, snapshot, data, decoded, fromFirestore_Options: _options });
      throw new Error("Error occurred when decoding doc! Not a result");
    }
    if (!decoded.isOk()) {
      console.error("Error occurred when decoding doc!", Object.defineProperties({ docId: snapshot.id, errors: unwrap_error(decoded).toArray() }, {
        data: {
          configurable: false,
          enumerable: true,
          get: () => data,
        },
        snapshot: {
          configurable: false,
          enumerable: true,
          get: () => snapshot,
        },
        fromFirestoreOptions: {
          configurable: false,
          enumerable: true,
          get: () => _options,
        },
      }));
    }
    return decoded
  };
  const _encode_gleam_type = (modelObject, _options) => {
    const encoded = encoder(modelObject);
    console.log("Encoding raw:", { input: modelObject, encoded });
    if (!(encoded instanceof Dict)) {
      console.warn("Top level encoded value is not an object / dict / map! This is probably incorrect!", encoded);
    }
    return encoded[0].entries().reduce((acc, [k, v]) => Object.assign(acc, { [k]: encodeValue(v, [...fieldPath, k]) }), {});
  }
  return Object.defineProperties({
    toFirestore: _encode_gleam_type,
    fromFirestore: _decode_gleam_type,
  }, {
    decoder: {
      configurable: false,
      writable: false,
      enumerable: true,
      value: decoder,
    },
    encoder: {
      configurable: false,
      writable: false,
      enumerable: true,
      value: encoder,
    },
  });
}

/**
 * 
 * @param {Firestore} firestore the firestore instance
 * @param {string} path the first part of the path to ensure that there is at least one segment
 * @param {string[]} pathSegments additional path segments
 * @param {(dbData: Dynamic) => Result<T, List<DecodeError>>} decoder the function used to convert the data from the database to the correct gleam type
 * @param {(data: T) => any} encoder the function used to convert the app data type to the type to be saved in the database
 * @returns 
 */
export function collectionImpl(firestore, path, pathSegments, decoder, encoder) {
  return (pathSegments.length + 1) % 2 === 0
    ? new Error(List.fromArray([path, ...pathSegments]))
    : new Ok(Object.defineProperties(
      collection(firestore, path, ...pathSegments).withConverter(converter(decoder, encoder)),
      {
        instance: {
          configurable: false,
          enumerable: false,
          get() {
            return this.firestore
          },
        },
        decoder: {
          configurable: false,
          writable: false,
          enumerable: true,
          value: decoder,
        },
        encoder: {
          configurable: false,
          writable: false,
          enumerable: true,
          value: encoder,
        },
      }
    ));
}

/**
 * 
 * @param {Firestore} firestore the firestore instance
 * @param {string} path the first part of the path to ensure that there is at least one segment
 * @param {string[]} pathSegments additional path segments
 * @param {(dbData: Dynamic) => Result<T, List<DecodeError>>} decoder the function used to convert the data from the database to the correct gleam type
 * @param {(data: T) => any} encoder the function used to convert the app data type to the type to be saved in the database
 * @returns 
 */
export function docImpl(firestore, path, pathSegments, decoder, encoder) {
  return (pathSegments.length + 1) % 2 === 0
    ? new Ok(Object.assign(
      doc(firestore, path, ...pathSegments).withConverter(converter(decoder, encoder)),
      { decoder, encoder },
    ))
    : new Error(List.fromArray([path, ...pathSegments]));
}

/**
 * 
 * @param {CollectionReference | DocumentReference} ref the reference to convert
 * @param {(dbData: Dynamic) => Result<T, List<DecodeError>>} decoder the function used to convert the data from the database to the correct gleam type
 * @param {(data: T) => any} encoder the function used to convert the app data type to the type to be saved in the database
 */
export function withConverter(ref, decoder, encoder) {
  return ref.withConverter(converter(decoder, encoder))
}


// ============== Snapshot ======================

/**
 * @param {DocumentSnapshot} snap 
 */
export const docExists = (snap) => snap.exists()
/**
 * @param {DocumentSnapshot} snap 
 */
export const docId = (snap) => snap.id
/**
 * @param {DocumentSnapshot} snap 
 */
export const docRef = (snap) => snap.ref
/**
 * @param {DocumentSnapshot} snap 
 */
export const getDataOpt = (snap) => {
  const data = snap.data();
  return data === undefined ? new None() : new Some(data)
}
/**
 * @param {QueryDocumentSnapshot} snap 
 */
export const getData = (snap) => snap.data()
/**
 * @param {DocumentSnapshot | QueryDocumentSnapshot} snap 
 */
export const getMetadata = (snap) => snap.metadata
/**
 * @param {SnapshotMetadata} metadata 
 */
export const hasPendingWrites = (metadata) => metadata.hasPendingWrites
/**
 * @param {SnapshotMetadata} metadata 
 */
export const isFromCache = (metadata) => metadata.fromCache
/**
 * @param {QuerySnapshot} snap 
 */
export const getSnapshotQuery = (snap) => snap.query
/**
 * @param {QuerySnapshot} snap 
 */
export const getQueryDocs = (snap) => List.fromArray(snap.docs)
/**
 * @param {QuerySnapshot} snap 
 */
export const getDocCount = (snap) => snap.size
/**
 * @param {QuerySnapshot} snap 
 */
export const isEmpty = (snap) => snap.empty
/**
 * @param {QuerySnapshot} snap 
 * @param {(doc: QueryDocumentSnapshot) => void} callback
 */
export const queryEach = (snap, callback) => snap.forEach(callback)
/**
 * @param {QuerySnapshot} snap 
 * @param {(import("firebase/firestore").SnapshotListenOptions) | undefined} listenOptions
 */
export const queryChanges = (snap, listenOptions) => List.fromArray(snap.docChanges(listenOptions).map(change => {
  switch (change.type) {
    case "added": return new Added(change.doc, change.newIndex);
    case "removed": return new Removed(change.doc, change.oldIndex);
    case "modified": return new Modified(change.doc, change.oldIndex, change.newIndex);
  }
}))


// ============== Database Mutation =============


export async function addDocImpl(ref, data) {
  console.log("Adding data:", data)//, ref.encoder(data));
  return await addDoc(ref, data).then(res => (console.log("Resolved:", res), res))
}

/**
 * 
 * @param {"Query"} query the collection or doc to query
 * @param {import(../gleam_stdlib/gleam/option.mjs).Option<SnapshotListenOptions>} optionsOpt the snapshot options
 * @param {(e: FirestoreError) => void} onError the error handler
 * @param {(snapshot: DocumentSnapshot<T>) => void} onChange the change handler
 * @returns 
 */
export function subscribe(query, optionsOpt, onError, onChange) {
  console.log("Subscribing:", { query, optionsOpt, onError, onChange });//XXX
  const observer = {
    next: (snapshot) => {
      snapshot.docChanges().forEach(change => {
        switch (change.type) {
          case "added": return onChange(new Added(change.doc, change.newIndex));
          case "removed": return onChange(new Removed(change.doc, change.oldIndex));
          case "modified": return onChange(new Modified(change.doc, change.oldIndex, change.newIndex));
        }
      })
    },
    error: (e) => {
      console.warn("Firestore subscription error thrown from ffi:", e)
      onError(e)
    },
  }
  if (is_none(optionsOpt)) {
    return onSnapshot(query, observer);
  }
  const { include_metadata_changes: includeMetadataChanges, cached_only } = unwrap(optionsOpt);
  return onSnapshot(query, { includeMetadataChanges, source: cached_only ? "cache" : "default" }, observer);
}