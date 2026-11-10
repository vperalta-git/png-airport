import { localEnvironment, LOCAL_PROJECT_ID } from "./local-environment";
const clean = () => ({
  FIREBASE_PROJECT_ID: LOCAL_PROJECT_ID,
  FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099",
  FIRESTORE_EMULATOR_HOST: "127.0.0.1:8085",
  FIREBASE_DATABASE_EMULATOR_HOST: "127.0.0.1:9000",
  FIREBASE_STORAGE_EMULATOR_HOST: "127.0.0.1:9199",
});
describe("local Firebase isolation", () => {
  it("uses only the demo project and local service addresses", () => {
    expect(localEnvironment(clean()).databaseURL).toContain(
      "http://127.0.0.1:9000",
    );
  });
  it.each([
    { FIREBASE_PROJECT_ID: "airport-png" },
    { NODE_ENV: "production" },
    { AEROTRANS_ENV: "staging" },
    { FIRESTORE_EMULATOR_HOST: "" },
    { FIREBASE_AUTH_EMULATOR_HOST: "example.com:9099" },
    { GOOGLE_APPLICATION_CREDENTIALS: "key.json" },
    { FIREBASE_SERVICE_ACCOUNT_KEY: "{}" },
    { FIREBASE_DATABASE_URL: "https://example.com" },
    { GOOGLE_CLOUD_PROJECT: "other" },
  ])("rejects unsafe or missing configuration %j", (change) => {
    expect(() => localEnvironment({ ...clean(), ...change })).toThrow();
  });
});
