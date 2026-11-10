import { test } from "node:test";
import assert from "node:assert/strict";
import { localEnv, projectId } from "./local.mjs";
test("local runner pins all Firebase services to a non-live demo project", () => {
  const env = localEnv({});
  assert.equal(env.FIREBASE_PROJECT_ID, projectId);
  assert.equal(env.FIREBASE_STORAGE_EMULATOR_HOST, "127.0.0.1:9199");
});
test("conflicting projects, credentials and endpoints cannot silently be overridden", () => {
  for (const change of [
    { FIREBASE_PROJECT_ID: "airport-png" },
    { GOOGLE_APPLICATION_CREDENTIALS: "key.json" },
    { FIRESTORE_EMULATOR_HOST: "example.com:443" },
    { AEROTRANS_ENV: "production" },
    { NODE_ENV: "production" },
    { FIREBASE_CONFIG: "{}" },
    { FIREBASE_DATABASE_URL: "https://example.com" },
  ]) {
    assert.throws(() => localEnv(change));
  }
});
