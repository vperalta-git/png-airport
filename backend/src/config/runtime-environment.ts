import {
  EMULATOR_KEYS,
  LOCAL_PROJECT_ID,
  localEnvironment,
} from "./local-environment";

// Only the separately approved test project can be used outside the emulators.
// This is intentionally not a general production-activation switch.
export const STAGING_PROJECT_ID = "aerotrans-png-test-7d7128";
export const PROTECTED_LIVE_PROJECT_ID = "airport-png-c866b";

export function runtimeIdentity(env: NodeJS.ProcessEnv = process.env) {
  const environment = env.AEROTRANS_ENV || "local";
  const projectId = env.FIREBASE_PROJECT_ID || LOCAL_PROJECT_ID;
  if (environment === "local" && projectId === LOCAL_PROJECT_ID) {
    return { environment: "local" as const, projectId };
  }
  if (environment === "staging" && projectId === STAGING_PROJECT_ID) {
    return { environment: "staging" as const, projectId };
  }
  throw new Error(
    "Only the local emulator or explicitly approved AeroTrans test project is supported.",
  );
}

export function runtimeEnvironment(env: NodeJS.ProcessEnv = process.env) {
  const identity = runtimeIdentity(env);
  if (identity.environment === "local") {
    return { ...identity, ...localEnvironment(env), serviceAccount: undefined };
  }
  for (const key of [
    ...EMULATOR_KEYS,
    "GOOGLE_APPLICATION_CREDENTIALS",
    "FIREBASE_CONFIG",
    "FIREBASE_TOKEN",
  ]) {
    if (env[key])
      throw new Error(
        key + " must be unset for the isolated hosted test runtime.",
      );
  }
  for (const key of ["GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT"]) {
    if (env[key] && env[key] !== identity.projectId)
      throw new Error(key + " conflicts with the approved test project.");
  }
  if (env.FIREBASE_DATABASE_URL || env.FIREBASE_STORAGE_BUCKET) {
    throw new Error(
      "Realtime database/storage providers are not configured for this hosted test batch.",
    );
  }
  let account: Record<string, string>;
  try {
    if (
      !env.FIREBASE_SERVICE_ACCOUNT_KEY ||
      env.FIREBASE_SERVICE_ACCOUNT_KEY.length > 32768
    )
      throw new Error();
    account = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_KEY);
    if (!account || typeof account !== "object" || Array.isArray(account))
      throw new Error();
  } catch {
    throw new Error(
      "A valid server-only Firebase service account JSON is required for the hosted test API.",
    );
  }
  if (
    account.type !== "service_account" ||
    account.project_id !== STAGING_PROJECT_ID ||
    typeof account.client_email !== "string" ||
    !account.client_email.endsWith(
      "@" + STAGING_PROJECT_ID + ".iam.gserviceaccount.com",
    ) ||
    typeof account.private_key !== "string" ||
    !account.private_key.startsWith("-----BEGIN PRIVATE KEY-----")
  ) {
    throw new Error(
      "The server credential must belong to the approved test project.",
    );
  }
  return {
    ...identity,
    endpoints: [],
    databaseURL: undefined,
    storageBucket: undefined,
    serviceAccount: {
      projectId: account.project_id,
      clientEmail: account.client_email,
      privateKey: account.private_key,
    },
  };
}

export function runtimeOrigins(env: NodeJS.ProcessEnv = process.env) {
  const identity = runtimeIdentity(env);
  const local = [5001, 5002, 5003, 5004].flatMap((port) => [
    "http://localhost:" + port,
    "http://127.0.0.1:" + port,
  ]);
  const origins =
    env.ALLOWED_ORIGINS?.split(",").map((value) => value.trim()) ??
    (identity.environment === "local" ? local : []);
  if (
    !origins.length ||
    origins.some((origin) => {
      if (identity.environment === "local") return !local.includes(origin);
      try {
        const url = new URL(origin);
        return (
          url.protocol !== "https:" ||
          url.origin !== origin ||
          url.username !== "" ||
          url.password !== "" ||
          url.hostname.includes("*") ||
          ["localhost", "127.0.0.1", "10.0.2.2"].includes(url.hostname)
        );
      } catch {
        return true;
      }
    })
  ) {
    throw new Error(
      "ALLOWED_ORIGINS must explicitly list supported origins for the configured runtime.",
    );
  }
  return origins;
}
