import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, relative, dirname } from "node:path";
import { fileURLToPath } from "node:url";
const root = dirname(dirname(fileURLToPath(import.meta.url)));
const ignored = new Set([
  ".flutter-plugins-dependencies",
  ".dart_tool",
  "build",
  "ephemeral",
  ".gradle",
  "Pods",
  ".symlinks",
]);
function files(path, base = path, result = new Map()) {
  if (!existsSync(path)) return result;
  for (const item of readdirSync(path, { withFileTypes: true })) {
    if (ignored.has(item.name)) continue;
    const full = join(path, item.name);
    if (item.isDirectory()) files(full, base, result);
    else
      result.set(
        relative(base, full).replaceAll("\\", "/"),
        readFileSync(full),
      );
  }
  return result;
}
const pairs = [
  ["client_flutter", "passenger_web"],
  ["control_room_flutter", "control_room_web"],
  ["driver_flutter", "driver_mobile"],
  ["supervisor_flutter", "admin_web"],
];
const result = pairs.map(([left, right]) => {
  const a = files(join(root, "apps", left)),
    b = files(join(root, "apps", right));
  const changed = [],
    onlyLeft = [],
    onlyRight = [];
  for (const [name, bytes] of a)
    if (!b.has(name)) onlyLeft.push(name);
    else if (!bytes.equals(b.get(name))) changed.push(name);
  for (const name of b.keys()) if (!a.has(name)) onlyRight.push(name);
  return {
    left,
    right,
    leftFiles: a.size,
    rightFiles: b.size,
    changed,
    onlyLeft,
    onlyRight,
  };
});
console.log(JSON.stringify(result, null, 2));
