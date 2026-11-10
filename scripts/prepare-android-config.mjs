import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
export const androidTestProject = "aerotrans-png-test-7d7128";
export const androidTestPackage =
  "com.pngtransfer.png_transfer_client.connected";
export const androidTestApi =
  "https://aerotrans-png-test-api-7d7128.vercel.app";
export function androidBuildConfig(raw) {
  let sdk;
  try {
    sdk = JSON.parse(raw);
  } catch {
    throw Error(
      "A valid public Android Firebase SDK configuration is required.",
    );
  }
  if (
    sdk?.project_info?.project_id !== androidTestProject ||
    !/^\d+$/.test(String(sdk?.project_info?.project_number)) ||
    raw.includes("PRIVATE KEY") ||
    sdk.private_key ||
    sdk.type === "service_account"
  )
    throw Error(
      "Only public SDK settings for the approved Android test project are supported.",
    );
  const matches = (sdk.client || []).filter(
    (c) =>
      c.client_info?.android_client_info?.package_name === androidTestPackage,
  );
  if (matches.length !== 1)
    throw Error(
      "Exactly one registered combined Android test client is required.",
    );
  const client = matches[0],
    sender = String(sdk.project_info.project_number),
    appId = client.client_info.mobilesdk_app_id,
    apiKey = client.api_key?.[0]?.current_key;
  if (
    typeof appId !== "string" ||
    !appId.startsWith("1:" + sender + ":android:") ||
    !appId.split(":").at(-1) ||
    typeof apiKey !== "string" ||
    !apiKey.trim()
  )
    throw Error("Complete native Firebase Android app identity is required.");
  return {
    AEROTRANS_ENV: "staging",
    FIREBASE_CLIENT_PLATFORM: "android",
    FIREBASE_PROJECT_ID: androidTestProject,
    API_BASE_URL: androidTestApi,
    FIREBASE_ANDROID_API_KEY: apiKey,
    FIREBASE_ANDROID_APP_ID: appId,
    FIREBASE_MESSAGING_SENDER_ID: sender,
  };
}
if (
  process.argv[1] &&
  resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const source = resolve(
      process.argv[2] || ".local-tools/hosted-test/firebase-android.json",
    ),
    output = resolve(
      process.argv[3] || ".local-tools/hosted-test/android-defines.json",
    );
  const config = androidBuildConfig(readFileSync(source, "utf8"));
  mkdirSync(dirname(output), { recursive: true });
  writeFileSync(output, JSON.stringify(config), { mode: 0o600 });
  console.log(
    "Validated native test Firebase settings; no server credentials included.",
  );
}
