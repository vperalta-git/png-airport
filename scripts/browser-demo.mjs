// Optional acceptance check using an already installed Playwright/Edge.
// No production endpoints, provider calls or new runtime dependencies.
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { readFile, stat, mkdir } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
import assert from "node:assert/strict";
import { localEnv, verify, projectId } from "./local.mjs";
Object.assign(process.env, localEnv());
await verify(process.env);
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const sheet = JSON.parse(
  await readFile(".local-tools/demo/accounts.json", "utf8"),
);
assert.equal(sheet.projectId, projectId);
const apps = [
  "passenger_web",
  "control_room_web",
  "driver_mobile",
  "admin_web",
];
const roles = ["PASSENGER", "DISPATCHER", "DRIVER", "SUPERVISOR"];
const servers = [],
  contexts = [],
  pages = [];
const browser = await chromium.launch({ channel: "msedge", headless: true });
let ownedBooking;
async function click(page, name) {
  const button = page.getByRole("button", { name, exact: true });
  await button.click();
}
function visibleText(page, value) {
  return page
    .getByText(value, { exact: true })
    .or(page.getByLabel(typeof value === "string" ? new RegExp(value) : value))
    .first();
}
try {
  for (const [i, app] of apps.entries()) {
    const base = resolve("apps", app, "build/web");
    const server = createServer(async (req, res) => {
      try {
        let file = resolve(
          base,
          "." +
            decodeURIComponent(new URL(req.url, "http://localhost").pathname),
        );
        if (file !== base && !file.startsWith(base + sep)) {
          res.writeHead(403).end();
          return;
        }
        if ((await stat(file)).isDirectory())
          file = resolve(file, "index.html");
        res.setHeader(
          "Content-Type",
          {
            ".html": "text/html",
            ".js": "application/javascript",
            ".mjs": "application/javascript",
            ".json": "application/json",
            ".wasm": "application/wasm",
            ".png": "image/png",
            ".css": "text/css",
          }[extname(file)] || "application/octet-stream",
        );
        res.end(await readFile(file));
      } catch {
        res.writeHead(404).end();
      }
    });
    await new Promise((ok, bad) => {
      server.once("error", bad);
      server.listen(5001 + i, "127.0.0.1", ok);
    });
    servers.push(server);
    const context = await browser.newContext({
      viewport: { width: 480, height: 1100 },
    });
    contexts.push(context);
    const external = [],
      errors = [];
    context.external = external;
    context.errors = errors;
    await context.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (
        url.protocol === "https:" &&
        url.hostname === "www.gstatic.com" &&
        url.pathname.startsWith("/firebasejs/11.9.1/") &&
        url.pathname.endsWith(".js")
      )
        return route.continue();
      if (
        url.protocol === "https:" &&
        url.hostname === "fonts.gstatic.com" &&
        /\.(ttf|woff2?)$/.test(url.pathname)
      )
        return route.continue();
      if (
        ["http:", "https:"].includes(url.protocol) &&
        !["127.0.0.1", "localhost"].includes(url.hostname)
      ) {
        external.push(url.origin);
        return route.abort();
      }
      return route.continue();
    });
    const page = await context.newPage();
    pages.push(page);
    page.setDefaultTimeout(20000);
    page.on("pageerror", (e) => errors.push(e.message));
    await page.goto("http://localhost:" + (5001 + i), { waitUntil: "load" });
    const semantics = page.locator("flt-semantics-placeholder");
    await semantics.waitFor({ state: "attached", timeout: 30000 });
    await semantics.evaluate((e) => e.click());
    await page.getByRole('button',{name:'Sign in',exact:true}).waitFor({timeout:30000});
    const account = sheet.accounts.find((a) => a.role === roles[i]);
    await page.locator('input[aria-label="Email"]').click();
    await page.waitForTimeout(150);
    await page.keyboard.type(account.email, { delay: 15 });
    await page.locator('input[aria-label="Password"]').click();
    await page.waitForTimeout(150);
    await page.keyboard.type(account.password, { delay: 15 });
    assert.equal(
      await page.locator('input[aria-label="Email"]').inputValue(),
      account.email,
    );
    assert.equal(
      await page.locator('input[aria-label="Password"]').inputValue(),
      account.password,
    );
    await page.keyboard.press("Tab");
    await click(page, "Sign in");
    try {
      await page
        .getByRole("button", { name: "Sign out", exact: true })
        .waitFor({ timeout: 30000 });
    } catch (error) {
      let body = await page.locator("body").innerText();
      for (const row of sheet.accounts)
        body = body.replaceAll(row.password, "[redacted]");
      console.error(
        app +
          " visible UI: " +
          body +
          "; blocked=" +
          JSON.stringify(external) +
          "; runtime=" +
          JSON.stringify(errors),
      );
      throw error;
    }
    assert.deepEqual(external, [], app + " attempted external data/API access");
    assert.deepEqual(errors, [], app + " runtime error");
    console.log(
      "PASS " +
        app +
        ": compiled Flutter UI signs in with real emulator identity and scoped backend profile",
    );
  }
  const [customer, control, driver, manager] = pages;
  await click(customer, "Book airport transfer");
  await customer.locator("input").first().click();
  await customer.waitForTimeout(150);
  await customer.keyboard.type("TEST ONLY browser acceptance Lae address", {
    delay: 15,
  });
  await customer.keyboard.press("Tab");
  const quoteResponse = customer.waitForResponse(
    (r) =>
      r.url().endsWith("/api/v1/quotes") && r.request().method() === "POST",
  );
  await click(customer, "Get server quote");
  const serverQuote = await (await quoteResponse).json();
  assert.equal(serverQuote.data?.pricing?.totalMinor, 10000);
  const response = customer.waitForResponse(
    (r) =>
      r.url().endsWith("/api/v1/bookings") && r.request().method() === "POST",
  );
  await click(customer, "Confirm demo reservation");
  const bookingResponse = await response;
  const envelope = await bookingResponse.json();
  assert.equal(
    envelope.success,
    true,
    JSON.stringify({
      status: bookingResponse.status(),
      error: envelope.error,
      request: bookingResponse.request().postDataJSON(),
    }),
  );
  ownedBooking = envelope.data;
  assert.equal(ownedBooking.payment.status, "PENDING");
  await visibleText(
    customer,
    new RegExp(ownedBooking.referenceNumber),
  ).waitFor();
  console.log(
    "PASS customer: server quote -> persisted unassigned reservation, payment pending",
  );
  // Use the actual UI in each app, with five-second authoritative polling.
  await visibleText(control, new RegExp(ownedBooking.referenceNumber)).click();
  await click(control, "Assign driver & vehicle");
  await click(control, "Continue");
  await visibleText(control, "Dispatched").waitFor();
  await visibleText(driver, new RegExp(ownedBooking.referenceNumber)).click();
  await click(driver, "Accept assignment & pre-trip checks");
  for (const name of [
    "Seatbelts checked",
    "Tyres checked",
    "Fuel checked",
    "Radio / phone checked",
  ])
    await driver.getByRole("checkbox", { name }).click();
  await click(driver, "Accept assignment");
  await click(driver, "Depart for airport");
  await visibleText(driver, "Driver En Route").waitFor();
  await click(driver, "I have arrived at the pickup point");
  await visibleText(driver, "At Airport").waitFor();
  await visibleText(customer, new RegExp(ownedBooking.referenceNumber)).click();
  const pickup = await (
    await customer.waitForFunction(() => {
      const labels =
        [...document.querySelectorAll("[aria-label]")]
          .map((e) => e.getAttribute("aria-label"))
          .join("\n") +
        "\n" +
        document.body.innerText;
      return (
        labels.match(/Passenger pickup code\s*(\d{6})/)?.[1] ||
        labels.match(/(?:^|\n)\s*(\d{6})\s*(?:\n|$)/)?.[1]
      );
    })
  ).jsonValue();
  await click(driver, "Verify passenger pickup");
  await driver.locator("input").click();
  await driver.keyboard.type(pickup, { delay: 15 });
  await driver.keyboard.press("Tab");
  await click(driver, "Continue");
  await visibleText(driver, "Passenger Verified").waitFor();
  await click(driver, "Start transfer");
  await visibleText(driver, "Transfer In Progress").waitFor();
  await click(driver, "Arrived at destination");
  await visibleText(driver, "Arrived Destination").waitFor();
  await click(driver, "Complete trip");
  await click(driver, "Confirm");
  await visibleText(driver, "Completed").waitFor();
  await visibleText(driver, "Payment: Pending").waitFor();
  console.log(
    "PASS driver UI: acceptance, departure, pickup OTP, transfer and completion; payment pending",
  );
  await visibleText(manager, "Management").click();
  await visibleText(manager, "Audit").click();
  await visibleText(
    manager,
    "Most recent 200 audit entries in your organization, branch and airport scope.",
  ).waitFor();
  for (const [i, page] of pages.entries()) {
    assert.deepEqual(
      contexts[i].external,
      [],
      apps[i] + " non-local data/API requests",
    );
    assert.deepEqual(contexts[i].errors, [], apps[i] + " runtime errors");
    await mkdir(".local-tools/demo/screenshots", { recursive: true });
    await page.screenshot({
      path: ".local-tools/demo/screenshots/" + roles[i].toLowerCase() + ".png",
    });
  }
  console.log(
    "PASS four-role Flutter UI: booking -> dispatch -> driver checks -> OTP pickup -> completed trip; manager audit; payment remains pending",
  );
} catch (error) {
  for (const [i, page] of pages.entries()) {
    let labels = await page
      .locator("[aria-label]")
      .evaluateAll((nodes) =>
        nodes.map((e) => e.getAttribute("aria-label")).join("\n"),
      )
      .catch(() => "(page closed)");
    labels += '\n'+await page.locator('body').innerText().catch(()=>'(page closed)');
    for (const row of sheet.accounts)
      labels = labels.replaceAll(row.password, "[redacted]");
    console.error(apps[i] + " final labels: " + labels);
  }
  throw error;
} finally {
  for (const context of contexts) await context.close();
  await browser.close();
  await Promise.all(servers.map((s) => new Promise((done) => s.close(done))));
  // Delete only the reservation this explicit test created, after validating ownership.
  if (ownedBooking) {
    const backendRequire = createRequire(
      new URL("../backend/package.json", import.meta.url),
    );
    const admin = backendRequire("firebase-admin"),
      app = admin.initializeApp({ projectId }, "browser-owned-test");
    try {
      const db = app.firestore(),
        ref = db.collection("bookings").doc(ownedBooking.id),
        snapshot = await ref.get(),
        b = snapshot.data();
      assert.equal(b.customerId, "demo-passenger");
      assert.equal(b.organizationId, "demo-aerotrans");
      assert.equal(
        b.input.destinationAddress,
        "TEST ONLY browser acceptance Lae address",
      );
      for (const [collection, field] of [
        ["booking_events", "bookingId"],
        ["audit_logs", "resourceId"],
        ["resource_locks", "bookingId"],
        ["booking_requests", "bookingId"],
      ]) {
        const rows = await db
          .collection(collection)
          .where(field, "==", b.id)
          .get();
        for (const row of rows.docs) await row.ref.delete();
      }
      for (const collection of ["pickup_challenges", "dispatch_assignments"])
        await db.collection(collection).doc(b.id).delete();
      await db.collection("quotations").doc(b.quotationId).delete();
      await ref.delete();
      console.log(
        "Cleaned only this browser test reservation and related records.",
      );
    } finally {
      await app.delete();
    }
  }
}
