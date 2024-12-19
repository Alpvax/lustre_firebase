import gleam/io
import gleam/option.{type Option, None, Some}

pub fn main() {
  io.println("Hello from lustre_firebase lib")
}

pub type FirebaseApp

pub type FirebaseConfig {
  FirebaseConfig(
    api_key: Option(String),
    auth_domain: Option(String),
    database_url: Option(String),
    project_id: Option(String),
    storage_bucket: Option(String),
    messaging_sender_id: Option(String),
    app_id: Option(String),
    measurement_id: Option(String),
  )
}

pub fn empty() -> FirebaseConfig {
  FirebaseConfig(
    project_id: None,
    api_key: None,
    auth_domain: None,
    database_url: None,
    storage_bucket: None,
    messaging_sender_id: None,
    app_id: None,
    measurement_id: None,
  )
}

pub fn config(project_id: String) -> FirebaseConfig {
  FirebaseConfig(..empty(), project_id: Some(project_id))
}

pub fn with_project_id(
  config: FirebaseConfig,
  project_id: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, project_id: Some(project_id))
}

pub fn with_api_key(config: FirebaseConfig, api_key: String) -> FirebaseConfig {
  FirebaseConfig(..config, api_key: Some(api_key))
}

pub fn with_auth_domain(
  config: FirebaseConfig,
  auth_domain: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, auth_domain: Some(auth_domain))
}

pub fn with_database_url(
  config: FirebaseConfig,
  database_url: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, database_url: Some(database_url))
}

pub fn with_storage_bucket(
  config: FirebaseConfig,
  storage_bucket: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, storage_bucket: Some(storage_bucket))
}

pub fn with_messaging_sender_id(
  config: FirebaseConfig,
  messaging_sender_id: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, messaging_sender_id: Some(messaging_sender_id))
}

pub fn with_app_id(config: FirebaseConfig, app_id: String) -> FirebaseConfig {
  FirebaseConfig(..config, app_id: Some(app_id))
}

pub fn with_measurement_id(
  config: FirebaseConfig,
  measurement_id: String,
) -> FirebaseConfig {
  FirebaseConfig(..config, measurement_id: Some(measurement_id))
}

@external(javascript, "./firebase_app.ffi.mjs", "initializeFirebaseApp")
pub fn initialize_app(config: FirebaseConfig) -> FirebaseApp

@external(javascript, "./firebase_app.ffi.mjs", "initializeFirebaseApp")
pub fn initialize_app_named(config: FirebaseConfig, name: String) -> FirebaseApp

@external(javascript, "./firebase_app.ffi.mjs", "getApp")
pub fn get_app() -> FirebaseApp

@external(javascript, "./firebase_app.ffi.mjs", "getApp")
pub fn get_app_named(name: String) -> FirebaseApp
