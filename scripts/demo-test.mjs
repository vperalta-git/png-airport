import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { localEnv, verify } from "./local.mjs";
const env = localEnv();
env.AEROTRANS_DEMO_RATES = "true";
await verify(env);
const require = createRequire(
  new URL("../backend/package.json", import.meta.url),
);
const child = spawn(
  process.execPath,
  [
    require.resolve("jest/bin/jest"),
    "--config",
    "test/jest-demo.json",
    "--runInBand",
  ],
  { cwd: new URL("../backend", import.meta.url), env, stdio: "inherit" },
);
child.on("exit", (code) => {
  process.exitCode = code ?? 1;
});
child.on("error", (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
