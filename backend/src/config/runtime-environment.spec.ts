import { localEnvironment, LOCAL_PROJECT_ID } from "./local-environment";
import {
  runtimeEnvironment,
  runtimeIdentity,
  runtimeOrigins,
  STAGING_PROJECT_ID,
  PROTECTED_LIVE_PROJECT_ID,
} from "./runtime-environment";

const local = () => ({
  FIREBASE_PROJECT_ID: LOCAL_PROJECT_ID,
  FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099",
  FIRESTORE_EMULATOR_HOST: "127.0.0.1:8085",
  FIREBASE_DATABASE_EMULATOR_HOST: "127.0.0.1:9000",
  FIREBASE_STORAGE_EMULATOR_HOST: "127.0.0.1:9199",
});
const account = () => ({
  type: "service_account",
  project_id: STAGING_PROJECT_ID,
  client_email: "test-api@" + STAGING_PROJECT_ID + ".iam.gserviceaccount.com",
  private_key:
    "-----BEGIN PRIVATE KEY-----\nTEST FIXTURE ONLY - NOT A REAL KEY",
});
const staging = () => ({
  AEROTRANS_ENV: "staging",
  NODE_ENV: "production",
  FIREBASE_PROJECT_ID: STAGING_PROJECT_ID,
  ALLOWED_ORIGINS: "https://png-airport-kappa.vercel.app",
  FIREBASE_SERVICE_ACCOUNT_KEY: JSON.stringify(account()),
});

describe("explicit hosted-test isolation", () => {
  it("preserves emulator requirements and supports a separate server-only test identity", () => {
    expect(runtimeEnvironment(local()).projectId).toBe(LOCAL_PROJECT_ID);
    expect(() =>
      localEnvironment({ ...local(), AEROTRANS_ENV: "staging" }),
    ).toThrow();
    const hosted = runtimeEnvironment(staging());
    expect(hosted.environment).toBe("staging");
    expect(hosted.serviceAccount.projectId).toBe(STAGING_PROJECT_ID);
    expect(hosted.endpoints).toEqual([]);
    expect(runtimeOrigins(staging())).toEqual([
      "https://png-airport-kappa.vercel.app",
    ]);
  });
  it.each([
    { FIREBASE_PROJECT_ID: PROTECTED_LIVE_PROJECT_ID },
    { FIREBASE_PROJECT_ID: "another-project" },
    { AEROTRANS_ENV: "production" },
    { FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099" },
    { GOOGLE_APPLICATION_CREDENTIALS: "unreviewed.json" },
    { FIREBASE_CONFIG: "{}" },
    { FIREBASE_SERVICE_ACCOUNT_KEY: "" },
    { FIREBASE_SERVICE_ACCOUNT_KEY: "not-json" },
    {
      FIREBASE_SERVICE_ACCOUNT_KEY: JSON.stringify({
        ...account(),
        project_id: PROTECTED_LIVE_PROJECT_ID,
      }),
    },
    {
      FIREBASE_SERVICE_ACCOUNT_KEY: JSON.stringify({
        ...account(),
        client_email: "wrong@other.iam.gserviceaccount.com",
      }),
    },
    { FIREBASE_DATABASE_URL: "https://unconfigured.firebaseio.com" },
  ])("refuses unsafe hosted configuration %j", (change) => {
    expect(() => runtimeEnvironment({ ...staging(), ...change })).toThrow();
  });
  it.each([
    "http://example.invalid",
    "https://example.invalid/path",
    "https://*.example.invalid",
    "https://user:pass@example.invalid",
    "https://localhost",
    "",
  ])("rejects unsafe hosted origin %s", (origin) => {
    expect(() =>
      runtimeOrigins({ ...staging(), ALLOWED_ORIGINS: origin }),
    ).toThrow();
  });
  it("never advertises production identity as a supported health target", () => {
    expect(() =>
      runtimeIdentity({
        ...staging(),
        FIREBASE_PROJECT_ID: PROTECTED_LIVE_PROJECT_ID,
      }),
    ).toThrow();
  });
});
