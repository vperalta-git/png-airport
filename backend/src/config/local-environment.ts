import { connect } from "node:net";

export const LOCAL_PROJECT_ID = "demo-aerotrans-png2";
export const EMULATOR_KEYS = [
  "FIREBASE_AUTH_EMULATOR_HOST",
  "FIRESTORE_EMULATOR_HOST",
  "FIREBASE_DATABASE_EMULATOR_HOST",
  "FIREBASE_STORAGE_EMULATOR_HOST",
] as const;

export function localEnvironment(env: NodeJS.ProcessEnv = process.env) {
  if (
    (env.AEROTRANS_ENV || "local") !== "local" ||
    env.NODE_ENV === "production"
  ) {
    throw new Error(
      "Batch A supports local emulators only. Production startup is disabled.",
    );
  }
  if (env.FIREBASE_PROJECT_ID !== LOCAL_PROJECT_ID) {
    throw new Error(
      "FIREBASE_PROJECT_ID must be demo-aerotrans-png2. Use npm run backend from the repository root.",
    );
  }
  for (const key of ["GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT"]) {
    if (env[key] && env[key] !== LOCAL_PROJECT_ID)
      throw new Error(key + " conflicts with the local demo project.");
  }
  for (const key of [
    "GOOGLE_APPLICATION_CREDENTIALS",
    "FIREBASE_SERVICE_ACCOUNT_KEY",
    "FIREBASE_CONFIG",
  ]) {
    if (env[key])
      throw new Error(key + " must be unset for emulator-only development.");
  }
  const endpoints = EMULATOR_KEYS.map((key) => {
    const value = env[key] || "";
    const match = /^(127\.0\.0\.1|localhost):([0-9]{1,5})$/.exec(value);
    if (!match || Number(match[2]) < 1 || Number(match[2]) > 65535) {
      throw new Error(key + " must specify a loopback emulator host:port.");
    }
    return { key, host: match[1], port: Number(match[2]) };
  });
  const databaseURL =
    "http://" +
    env.FIREBASE_DATABASE_EMULATOR_HOST +
    "/?ns=" +
    LOCAL_PROJECT_ID +
    "-default-rtdb";
  const storageBucket = LOCAL_PROJECT_ID + ".appspot.com";
  if (env.FIREBASE_DATABASE_URL && env.FIREBASE_DATABASE_URL !== databaseURL)
    throw new Error("FIREBASE_DATABASE_URL conflicts with the local emulator.");
  if (
    env.FIREBASE_STORAGE_BUCKET &&
    env.FIREBASE_STORAGE_BUCKET !== storageBucket
  )
    throw new Error(
      "FIREBASE_STORAGE_BUCKET conflicts with the local demo bucket.",
    );
  return { projectId: LOCAL_PROJECT_ID, endpoints, databaseURL, storageBucket };
}

export async function requireEmulators(
  config: ReturnType<typeof localEnvironment>,
) {
  await Promise.all(
    config.endpoints.map(
      ({ key, host, port }) =>
        new Promise<void>((resolve, reject) => {
          const socket = connect({ host, port });
          socket.setTimeout(2000);
          const fail = () => {
            socket.destroy();
            reject(
              new Error(
                key +
                  " unavailable at " +
                  host +
                  ":" +
                  port +
                  ". Start npm run emulators.",
              ),
            );
          };
          socket.once("error", fail);
          socket.once("timeout", fail);
          socket.once("connect", () => {
            socket.destroy();
            resolve();
          });
        }),
    ),
  );
}
