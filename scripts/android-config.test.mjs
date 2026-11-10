import test from "node:test";
import assert from "node:assert/strict";
import {
  androidBuildConfig,
  androidTestProject,
  androidTestPackage,
} from "./prepare-android-config.mjs";
const fixture = () => ({
  project_info: { project_id: androidTestProject, project_number: "123" },
  client: [
    {
      client_info: {
        mobilesdk_app_id: "1:123:android:testfixture",
        android_client_info: { package_name: androidTestPackage },
      },
      api_key: [{ current_key: "public-test-placeholder" }],
    },
  ],
});
test("native configuration is scoped to the registered Android test app and hosted API", () => {
  const parsed = androidBuildConfig(JSON.stringify(fixture()));
  assert.equal(parsed.FIREBASE_CLIENT_PLATFORM, "android");
  assert.equal(parsed.FIREBASE_ANDROID_APP_ID, "1:123:android:testfixture");
  assert.ok(!("FIREBASE_SERVICE_ACCOUNT_KEY" in parsed));
  assert.ok(!("FIREBASE_WEB_APP_ID" in parsed));
  assert.ok(parsed.API_BASE_URL.startsWith("https://"));
  for (const edit of [
    (s) => (s.project_info.project_id = "airport-png-c866b"),
    (s) =>
      (s.client[0].client_info.android_client_info.package_name = "other.app"),
    (s) => (s.client[0].client_info.mobilesdk_app_id = "1:123:web:testfixture"),
    (s) => (s.client[0].api_key = []),
    (s) => (s.private_key = "-----BEGIN PRIVATE KEY-----"),
    (s) => s.client.push(s.client[0]),
  ]) {
    const s = fixture();
    edit(s);
    assert.throws(() => androidBuildConfig(JSON.stringify(s)));
  }
});
