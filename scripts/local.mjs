import { spawn } from "node:child_process";
import { connect } from "node:net";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";
import { readFileSync, existsSync, mkdirSync } from "node:fs";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
export const projectId = "demo-aerotrans-png2";
export const apps = [
  "passenger_web",
  "control_room_web",
  "driver_mobile",
  "admin_web",
];
export function localEnv(inherited = process.env) {
  for (const key of [
    "GOOGLE_APPLICATION_CREDENTIALS",
    "FIREBASE_SERVICE_ACCOUNT_KEY",
    "FIREBASE_CONFIG",
    "FIREBASE_TOKEN",
    "GOOGLE_OAUTH_ACCESS_TOKEN",
  ]) {
    if (inherited[key])
      throw new Error("Unset " + key + " before starting local tools.");
  }
  for (const key of [
    "FIREBASE_PROJECT_ID",
    "GOOGLE_CLOUD_PROJECT",
    "GCLOUD_PROJECT",
  ]) {
    if (inherited[key] && inherited[key] !== projectId)
      throw new Error(key + " conflicts with the isolated demo project.");
  }
  if (inherited.AEROTRANS_ENV && inherited.AEROTRANS_ENV !== "local")
    throw new Error("Only local mode is supported.");
  if (inherited.NODE_ENV === "production")
    throw new Error("Production mode is disabled in local tooling.");
  const env = {
    ...inherited,
    AEROTRANS_ENV: "local",
    NODE_ENV: "development",
    CI: "true",
    XDG_CONFIG_HOME: join(root, ".local-tools/config"),
    FIREBASE_CLI_DISABLE_MOTD: "true",
    FIREBASE_CLI_DISABLE_USAGE_REPORTING: "true",
    FIREBASE_PROJECT_ID: projectId,
    GCLOUD_PROJECT: projectId,
    GOOGLE_CLOUD_PROJECT: projectId,
    ALLOWED_ORIGINS:
      "http://localhost:5001,http://localhost:5002,http://localhost:5003,http://localhost:5004",
  };
  const config = JSON.parse(
    readFileSync(join(root, "firebase.local.json"), "utf8"),
  );
  for (const [service, key] of Object.entries({
    auth: "FIREBASE_AUTH_EMULATOR_HOST",
    firestore: "FIRESTORE_EMULATOR_HOST",
    database: "FIREBASE_DATABASE_EMULATOR_HOST",
    storage: "FIREBASE_STORAGE_EMULATOR_HOST",
  })) {
    const entry = config.emulators[service];
    if (entry.host !== "127.0.0.1")
      throw new Error("Emulators must bind to loopback.");
    const expected = entry.host + ":" + entry.port;
    if (inherited[key] && inherited[key] !== expected)
      throw new Error(key + " conflicts with firebase.local.json.");
    env[key] = expected;
  }
  if (inherited.FIREBASE_DATABASE_URL || inherited.FIREBASE_STORAGE_BUCKET)
    throw new Error("Unset Firebase database/bucket overrides in local mode.");
  return env;
}
export async function verify(env) {
  await Promise.all(
    [
      "FIREBASE_AUTH_EMULATOR_HOST",
      "FIRESTORE_EMULATOR_HOST",
      "FIREBASE_DATABASE_EMULATOR_HOST",
      "FIREBASE_STORAGE_EMULATOR_HOST",
    ].map(
      (key) =>
        new Promise((resolve, reject) => {
          const [host, port] = env[key].split(":");
          const socket = connect({ host, port: Number(port) });
          socket.setTimeout(2000);
          const fail = () => {
            socket.destroy();
            reject(
              new Error(
                key + " is unavailable. Start npm run emulators first.",
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
function run(command, args, env, cwd = root) {
  const child = spawn(command, args, { env, cwd, stdio: "inherit" });
  child.on("error", (error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
  child.on("exit", (code) => {
    process.exitCode = code ?? 1;
  });
}
async function main() {
  const [action, ...args] = process.argv.slice(2);
  const env = localEnv();
  const firebase = join(
    root,
    "node_modules/firebase-tools/lib/bin/firebase.js",
  );
  if (action === "emulators") {
    mkdirSync(join(root, ".emulator-data"), { recursive: true });
    if (args.length)
      throw new Error("Emulator options are fixed for local isolation.");
    run(
      process.execPath,
      [
        firebase,
        "emulators:start",
        "--only",
        "auth,firestore,database,storage",
        "--project",
        projectId,
        "--config",
        join(root, "firebase.local.json"),
        "--export-on-exit",
        join(root, ".emulator-data/runtime"),
        ...(existsSync(
          join(root, ".emulator-data/runtime/firebase-export-metadata.json"),
        )
          ? ["--import", join(root, ".emulator-data/runtime")]
          : []),
      ],
      env,
    );
  } else if (action === "save-demo") {
    mkdirSync(join(root, ".emulator-data"), { recursive: true });
    await verify(env);
    if (
      env.FIREBASE_EMULATOR_HUB &&
      env.FIREBASE_EMULATOR_HUB !== "127.0.0.1:4400"
    )
      throw new Error("Demo export requires the loopback emulator hub.");
    run(
      process.execPath,
      [
        firebase,
        "emulators:export",
        join(root, ".emulator-data/runtime"),
        "--force",
        "--project",
        projectId,
        "--config",
        join(root, "firebase.local.json"),
      ],
      { ...env, FIREBASE_EMULATOR_HUB: "127.0.0.1:4400" },
    );
  } else if (action === "backend" || action === "demo-backend") {
    if (action === "demo-backend") env.AEROTRANS_DEMO_RATES = "true";
    await verify(env);
    await new Promise((resolve, reject) => {
      const compile = spawn(
        process.execPath,
        [
          join(root, "backend/node_modules/typescript/bin/tsc"),
          "-p",
          join(root, "packages/types/tsconfig.json"),
        ],
        { env, cwd: root, stdio: "inherit" },
      );
      compile.once("error", reject);
      compile.once("exit", (code) =>
        code === 0
          ? resolve()
          : reject(new Error("Shared contract compilation failed.")),
      );
    });
    if (action === "demo-backend") {
      await new Promise((resolve, reject) => {
        const compile = spawn(
          process.execPath,
          [join(root, "backend/node_modules/@nestjs/cli/bin/nest.js"), "build"],
          { env, cwd: join(root, "backend"), stdio: "inherit" },
        );
        compile.once("error", reject);
        compile.once("exit", (code) =>
          code === 0
            ? resolve()
            : reject(new Error("Demo backend compilation failed.")),
        );
      });
      run(
        process.execPath,
        [join(root, "backend/dist/main.js")],
        env,
        join(root, "backend"),
      );
    } else {
      run(
        process.execPath,
        [
          join(root, "backend/node_modules/@nestjs/cli/bin/nest.js"),
          "start",
          "--watch",
        ],
        env,
        join(root, "backend"),
      );
    }
  } else if (action === "verify") {
    await verify(env);
    console.log("All four local emulators reachable for " + projectId);
  } else if (action === "test") {
    await verify(env);
    run(process.execPath, ["--test", "scripts/emulator-smoke.test.mjs"], env);
  } else if (action === "flutter") {
    const [app, device = "chrome"] = args;
    if (!apps.includes(app) || args.length > 2)
      throw new Error("Choose one of: " + apps.join(", "));
    await verify(env);
    const android =
      device !== "chrome" && device !== "edge" && device !== "windows";
    const flags = [
      "run",
      "-d",
      device,
      "--dart-define=EMULATOR_HOST=" +
        (android && device.startsWith("emulator-") ? "10.0.2.2" : "127.0.0.1"),
    ];
    if (!android) flags.push("--web-port=" + (5001 + apps.indexOf(app)));
    // cmd.exe is used only to launch the fixed Flutter batch executable, with
    // validated app/device arguments, never for filesystem operations.
    if (!/^[a-zA-Z0-9_.:-]+$/.test(device))
      throw new Error("Invalid device identifier.");
    if (process.platform === "win32")
      run(
        "cmd.exe",
        ["/d", "/c", "flutter", ...flags],
        env,
        join(root, "apps", app),
      );
    else run("flutter", flags, env, join(root, "apps", app));
  } else
    throw new Error(
      "Use npm run emulators, backend, flutter -- <app> [device], verify:emulators or test:emulators.",
    );
}
if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url)
  main().catch((error) => {
    console.error("Local setup: " + error.message);
    process.exitCode = 1;
  });
