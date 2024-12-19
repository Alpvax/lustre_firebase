import { initializeApp, getApp as getAppInternal } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js";
// import { initializeApp } from "firebase/app";
import { unwrap } from "../gleam_stdlib/gleam/option.mjs";

export const getApp = getAppInternal;

function mapVarName(varName) {
  return varName.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
}

export function initializeFirebaseApp(config, name) {
  let appConfig = {};
  for (const [k, v] of Object.entries(config)) {
    const val = unwrap(v);
    if (val !== undefined) {
      appConfig[mapVarName(k)] = val;
    }
  }
  return initializeApp(appConfig, name);
}