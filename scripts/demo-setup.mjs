import { createRequire } from "node:module";
import { randomBytes } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { localEnv, verify, projectId } from "./local.mjs";
const require = createRequire(
  new URL("../backend/package.json", import.meta.url),
);
Object.assign(process.env, localEnv());
await verify(process.env);
const admin = require("firebase-admin");
const scope = {
  organizationId: "demo-aerotrans",
  branchId: "demo-lae",
  airportId: "airport_nadzab_lae",
};
const app = admin.initializeApp({
  projectId,
  databaseURL:
    "http://" +
    process.env.FIREBASE_DATABASE_EMULATOR_HOST +
    "/?ns=" +
    projectId +
    "-default-rtdb",
});
const folder = resolve(".local-tools/demo"),
  sheetPath = resolve(folder, "accounts.json");
const saved = existsSync(sheetPath)
  ? JSON.parse(readFileSync(sheetPath, "utf8"))
  : { accounts: [] };
const accounts = [];
try {
  for (const [role, label] of [
    ["PASSENGER", "Customer"],
    ["DISPATCHER", "Control Room"],
    ["DRIVER", "Driver"],
    ["SUPERVISOR", "Supervisor"],
  ]) {
    const uid = "demo-" + role.toLowerCase(),
      email = role.toLowerCase() + "@aerotrans-demo.invalid";
    const previous = saved.accounts.find((a) => a.uid === uid),
      password =
        previous?.password || randomBytes(18).toString("base64url") + "!7a";
    const profileRef = app.firestore().collection("users").doc(uid),
      profile = await profileRef.get();
    if (profile.exists && profile.data().managedBy !== "aerotrans-demo-setup")
      throw new Error(
        "Refusing to overwrite an account not owned by the demo setup: " + uid,
      );
    let user;
    try {
      user = await app.auth().getUser(uid);
    } catch (e) {
      if (e.code !== "auth/user-not-found") throw e;
    }
    if (!user)
      await app
        .auth()
        .createUser({ uid, email, password, displayName: "Demo " + label });
    else {
      if (
        user.email !== email ||
        (!profile.exists &&
          user.customClaims?.managedBy !== "aerotrans-demo-setup")
      )
        throw new Error(
          "Refusing to overwrite an Auth identity not owned by demo setup: " +
            uid,
        );
      await app
        .auth()
        .updateUser(uid, {
          disabled: false,
          ...(!previous ? { password } : {}),
        });
    }
    await app.auth().setCustomUserClaims(uid, {
      role,
      organizationId: scope.organizationId,
      branchIds: [scope.branchId],
      airportIds: [scope.airportId],
      managedBy: "aerotrans-demo-setup",
    });
    await profileRef.set(
      {
        uid,
        email,
        fullName: "Demo " + label,
        role,
        active: true,
        ...scope,
        available: role === "DRIVER",
        managedBy: "aerotrans-demo-setup",
        createdAt: profile.data()?.createdAt || new Date().toISOString(),
      },
      { merge: true },
    );
    accounts.push({ uid, role, label, email, password });
  }
  for (const [id, makeModel, category, capacity, luggage, plate] of [
    ["demo-sedan", "DEMO Sedan", "STANDARD_SEDAN", 3, 2, "DEMO-LAE-01"],
    ["demo-suv", "DEMO SUV", "EXECUTIVE_SUV", 5, 4, "DEMO-LAE-02"],
  ]) {
    const ref = app.firestore().collection("vehicles").doc(id),
      row = await ref.get();
    if (row.exists) {
      if (row.data().managedBy !== "aerotrans-demo-setup")
        throw new Error("Vehicle ID belongs to another record");
      continue;
    }
    const plateRef = app
      .firestore()
      .collection("vehicle_plates")
      .doc(encodeURIComponent(scope.organizationId + ":" + plate));
    await app.firestore().runTransaction(async (tx) => {
      const existingPlate = await tx.get(plateRef);
      if (existingPlate.exists)
        throw new Error(
          "Demo plate already belongs to another vehicle; existing work was preserved.",
        );
      tx.create(ref, {
        id,
        ...scope,
        makeModel,
        category,
        passengerCapacity: capacity,
        luggageCapacity: luggage,
        registrationPlate: plate,
        status: "ACTIVE",
        managedBy: "aerotrans-demo-setup",
        createdAt: new Date().toISOString(),
      });
      tx.create(plateRef, { vehicleId: id });
    });
  }
  mkdirSync(folder, { recursive: true });
  writeFileSync(
    sheetPath,
    JSON.stringify({ projectId, mode: "ISOLATED DEMO", accounts }, null, 2),
    { mode: 0o600 },
  );
  console.log(
    "Demo accounts/fleet prepared. Credentials are in the ignored local file: " +
      sheetPath,
  );
  console.log(
    "These are emulator-only identities. No production accounts or bookings were created.",
  );
} finally {
  await app.delete();
}
