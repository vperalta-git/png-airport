import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { randomUUID } from "node:crypto";
import { localEnv, verify, projectId } from "./local.mjs";
const require = createRequire(
  new URL("../backend/package.json", import.meta.url),
);
const admin = require("firebase-admin");
test("Auth, Firestore, RTDB and Storage use only isolated local demo data", async () => {
  Object.assign(process.env, localEnv());
  await verify(process.env);
  const app = admin.initializeApp(
    {
      projectId,
      databaseURL:
        "http://" +
        process.env.FIREBASE_DATABASE_EMULATOR_HOST +
        "/?ns=" +
        projectId +
        "-default-rtdb",
      storageBucket: projectId + ".appspot.com",
    },
    "batch-a-smoke",
  );
  const id = "batch-a-" + randomUUID(),
    email = id + "@example.invalid";
  const doc = app.firestore().collection("_batch_a_test").doc(id);
  const ref = app.database().ref("_batch_a_test/" + id);
  const file = app
    .storage()
    .bucket()
    .file("_batch_a_test/" + id + ".txt");
  let user;
  try {
    user = await app
      .auth()
      .createUser({ uid: id, email, password: "TEST-ONLY-Emulator123!" });
    const authResponse = await fetch(
      "http://" +
        process.env.FIREBASE_AUTH_EMULATOR_HOST +
        "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator-key",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          password: "TEST-ONLY-Emulator123!",
          returnSecureToken: true,
        }),
        signal: AbortSignal.timeout(5000),
      },
    );
    const auth = await authResponse.json();
    assert.equal(authResponse.status, 200);
    assert.equal((await app.auth().verifyIdToken(auth.idToken)).uid, id);
    const escalation = await fetch(
      "http://" +
        process.env.FIRESTORE_EMULATOR_HOST +
        "/v1/projects/" +
        projectId +
        "/databases/(default)/documents/users/" +
        id,
      {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Authorization: "Bearer " + auth.idToken,
        },
        body: JSON.stringify({
          fields: { role: { stringValue: "SUPER_ADMIN" } },
        }),
        signal: AbortSignal.timeout(5000),
      },
    );
    assert.equal(
      escalation.status,
      403,
      "A signed-in client must not grant itself a role",
    );
    await doc.set({ source: "TEST-ONLY-BATCH-A", projectId });
    assert.equal((await doc.get()).data().projectId, projectId);
    await ref.set({ source: "TEST-ONLY-BATCH-A", projectId });
    assert.equal((await ref.get()).val().projectId, projectId);
    await file.save(Buffer.from("TEST-ONLY-BATCH-A"), { resumable: false });
    assert.equal((await file.download())[0].toString(), "TEST-ONLY-BATCH-A");
  } finally {
    const cleanup = await Promise.allSettled([
      doc.delete(),
      ref.remove(),
      file.delete({ ignoreNotFound: true }),
      ...(user ? [app.auth().deleteUser(user.uid)] : []),
    ]);
    await app.delete();
    for (const result of cleanup)
      if (result.status === "rejected") throw result.reason;
  }
});
