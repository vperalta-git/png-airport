import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
const args = process.argv.slice(2);
const option = args.indexOf("--serial"),
  requested = option >= 0 ? args[option + 1] : null;
if (option >= 0 && !requested) throw new Error("--serial requires a device ID");
if (args.includes("--install") && args.includes("--remove-forwards"))
  throw new Error("Install and remove-forwards cannot be combined");
if (
  args.some(
    (v, i) =>
      !["--serial", "--install", "--remove-forwards"].includes(v) &&
      !(option >= 0 && i === option + 1),
  )
)
  throw new Error("Use --serial <id>, --install or --remove-forwards");
if (requested && !/^[A-Za-z0-9_.:-]+$/.test(requested))
  throw new Error("Invalid serial");
const adb = (list) => execFileSync("adb", list, { encoding: "utf8" });
const devices = adb(["devices"])
  .split(/\r?\n/)
  .filter((line) => /\tdevice$/.test(line))
  .map((line) => line.split("\t")[0])
  .filter((s) => !s.startsWith("emulator-"));
const serial = requested || (devices.length === 1 && devices[0]);
if (!serial || !devices.includes(serial))
  throw new Error(
    "Connect one real Android phone by USB, enable USB debugging and accept its authorization prompt. Use --serial if multiple phones are connected.",
  );
const run = (list) => adb(["-s", serial, ...list]);
for (const port of [8080, 9099, 8085, 9000, 9199])
  run(
    args.includes("--remove-forwards")
      ? ["reverse", "--remove", "tcp:" + port]
      : ["reverse", "tcp:" + port, "tcp:" + port],
  );
if (args.includes("--install")) {
  for (const name of ["customer", "control-room", "driver", "supervisor"]) {
    const apk = resolve(
      ".local-tools/demo/apks/aerotrans-" + name + "-demo.apk",
    );
    if (!existsSync(apk)) throw new Error("Build the demo APKs first: " + apk);
    console.log(run(["install", "-r", apk]).trim());
  }
}
console.log(
  "Demo USB forwarding configured for " +
    serial +
    ". Keep the phone connected to this computer.",
);
