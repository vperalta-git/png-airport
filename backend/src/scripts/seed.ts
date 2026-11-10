import * as admin from "firebase-admin";

async function seed() {
  throw new Error(
    "Seed disabled in Batch A. Use isolated test fixtures; no operational/demo organization data is loaded.",
  );
  console.log(
    "--- Seeding Firestore for PNG Airport Transfer & Security Platform ---",
  );
  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || "png-airport-transfer",
    });
  }

  const db = admin.firestore();

  // 1. Organization & Branch
  await db.collection("organizations").doc("org_morobe_lae").set({
    name: "Morobe Secure Transit & Aviation Logistics Ltd",
    registrationNumber: "PNG-IPA-109284",
    tin: "TIN-908234-LAE",
    country: "Papua New Guinea",
    province: "Morobe",
    city: "Lae",
    createdAt: new Date().toISOString(),
  });

  await db.collection("branches").doc("branch_nadzab_lae").set({
    organizationId: "org_morobe_lae",
    name: "Nadzab Airport Base Command & Depot",
    airportCode: "AYNZ",
    city: "Lae",
    address: "Nadzab Tomodachi International Airport Access Rd",
    emergencyRadioVhf: "156.800 MHz",
    phone: "+675 472 0000",
    createdAt: new Date().toISOString(),
  });

  console.log("Seeded Organization & Branch.");
  console.log("Seeding complete successfully.");
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
