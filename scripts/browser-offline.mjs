// Optional acceptance test: compiled Flutter UI + real browser local storage.
// Only static assets for that app are allowed. All APIs/Firebase/internet are blocked.
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { readFile, stat, mkdir } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
import assert from "node:assert/strict";
const require = createRequire(import.meta.url),
  { chromium } = require("playwright");
let apps = ["passenger_web", "control_room_web", "driver_mobile", "admin_web"];
if (process.argv.includes("--customer-only")) apps = apps.slice(0, 1);
const labels = ["Customer", "Control Room", "Driver", "Supervisor"];
const servers = [],
  contexts = [],
  pages = [];
const browser = await chromium.launch({ channel: "msedge", headless: true });
const text = (p, s) =>
  p
    .getByText(s, { exact: true })
    .or(p.getByLabel(typeof s === "string" ? new RegExp(s) : s))
    .first();
const click = (p, name) => p.getByRole("button", { name, exact: true }).click();
async function semantics(p) {
  // Allow the restored Flutter route's first layout before enabling DOM semantics.
  await p.waitForTimeout(350);
  const placeholder = p.locator("flt-semantics-placeholder");
  await placeholder.waitFor({ state: "attached", timeout: 30000 });
  await placeholder.evaluate((e) => e.click());
}
async function read(p) {
  return (
    (await p
      .locator("[aria-label]")
      .evaluateAll((nodes) =>
        nodes.map((n) => n.getAttribute("aria-label")).join("\n"),
      )) +
    "\n" +
    (await p.locator("body").innerText())
  );
}
let current = "Customer - Demo Customer";
async function persona(p, next) {
  await p.getByRole("button", { name: new RegExp(current) }).click();
  await text(p, next).click();
  current = next;
  await p.getByRole("button", { name: new RegExp(next) }).waitFor();
}
async function back(p) {
  await click(p, "Back");
  await p.waitForTimeout(250);
}
try {
  for (const [i, app] of apps.entries()) {
    const base = resolve("apps", app, "build/web"),
      port = 5101 + i;
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
            ".ttf": "font/ttf",
            ".otf": "font/otf",
            ".png": "image/png",
          }[extname(file)] || "application/octet-stream",
        );
        res.end(await readFile(file));
      } catch {
        res.writeHead(404).end();
      }
    });
    await new Promise((ok, bad) => {
      server.once("error", bad);
      server.listen(port, "127.0.0.1", ok);
    });
    servers.push(server);
    const context = await browser.newContext({
      viewport: { width: 430, height: 1000 },
    });
    context.blocked = [];
    context.rendererFontAttempts = [];
    context.errors = [];
    contexts.push(context);
    await context.route("**/*", (route) => {
      const url = new URL(route.request().url());
      if (
        ["http:", "https:"].includes(url.protocol) &&
        !(
          url.protocol === "http:" &&
          ["localhost", "127.0.0.1"].includes(url.hostname) &&
          url.port === String(port)
        )
      ) {
        // Fulfil the browser engine's fallback font using the bundled local font.
        // The request is intercepted; no bytes are obtained from the internet.
        if (
          url.hostname === "fonts.gstatic.com" &&
          /\.(woff2?|ttf)$/.test(url.pathname)
        ) {
          context.rendererFontAttempts.push(url.origin + url.pathname);
          return readFile(
            "packages/png_transfer_flutter_core/fonts/Roboto-Regular.ttf",
          ).then((body) =>
            route.fulfill({ status: 200, contentType: "font/ttf", body }),
          );
        }
        context.blocked.push(url.origin + url.pathname);
        return route.abort();
      }
      return route.continue();
    });
    const page = await context.newPage();
    pages.push(page);
    page.setDefaultTimeout(20000);
    page.on("pageerror", (e) =>
      context.errors.push({
        message: e.message,
        stack: e.stack,
        phase: context.phase,
      }),
    );
    await page.goto("http://localhost:" + port, { waitUntil: "load" });
    await semantics(page);
    await click(page, "Start " + labels[i] + " demo");
    await text(page, "AeroTrans " + labels[i]).waitFor();
    assert.deepEqual(
      context.blocked,
      [],
      app + " tried to access a network service",
    );
    assert.deepEqual(context.errors, [], app + " runtime errors");
    console.log(
      "PASS " +
        app +
        ": offline startup, practice data and role home without Firebase/API/internet",
    );
  }
  const page = pages[0];
  contexts[0].phase = "booking";
  const before = new Set((await read(page)).match(/OFFLINE-BK-\d+/g));
  await click(page, "Book airport transfer");
  const address = page.locator("input").first();
  await address.click();
  await page.waitForTimeout(150);
  await page.keyboard.type("DEMO offline acceptance Lae hotel", { delay: 10 });
  await page.keyboard.press("Tab");
  await click(page, "Get demo quote");
  await click(page, "Confirm demo reservation");
  await page.waitForFunction(
    (old) => {
      const value =
        [...document.querySelectorAll("[aria-label]")]
          .map((e) => e.getAttribute("aria-label"))
          .join("\n") +
        "\n" +
        document.body.innerText;
      return (value.match(/OFFLINE-BK-\d+/g) || []).some(
        (id) => !old.includes(id),
      );
    },
    [...before],
  );
  const reference = (await read(page))
    .match(/OFFLINE-BK-\d+/g)
    .find((id) => !before.has(id));
  assert.ok(reference);
  contexts[0].phase = "control";
  await persona(page, "Control Room - Demo Control Room");
  await text(page, reference).click();
  await click(page, "Assign driver & vehicle");
  await click(page, "Continue");
  await text(page, "Dispatched").waitFor();
  await back(page);
  await persona(page, "Driver - Demo Driver Two");
  await text(page, reference).click();
  await click(page, "Accept assignment & pre-trip checks");
  for (const name of [
    "Seatbelts checked",
    "Tyres checked",
    "Fuel checked",
    "Radio / phone checked",
  ])
    await page.getByRole("checkbox", { name }).click();
  await click(page, "Accept assignment");
  await click(page, "Depart for airport");
  await text(page, "Driver En Route").waitFor();
  await click(page, "I have arrived at the pickup point");
  await text(page, "At Airport").waitFor();
  await back(page);
  await persona(page, "Customer - Demo Customer");
  await text(page, reference).click();
  const code = await (
    await page.waitForFunction(() => {
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
  contexts[0].phase = "reload";
  await page.reload({ waitUntil: "load" });
  await semantics(page);
  await page
    .getByRole("button", { name: /Customer - Demo Customer/ })
    .waitFor();
  await text(page, reference).click();
  assert.ok(
    (await read(page)).includes(code),
    "Pickup code should survive reload",
  );
  await back(page);
  await persona(page, "Driver - Demo Driver Two");
  await text(page, reference).click();
  contexts[0].phase = "verify";
  await click(page, "Verify passenger pickup");
  await page.locator("input").click();
  await page.waitForTimeout(150);
  await page.keyboard.type(code, { delay: 30 });
  await page.keyboard.press("Tab");
  await click(page, "Continue");
  await text(page, "Passenger Verified").waitFor();
  await click(page, "Start transfer");
  await text(page, "Transfer In Progress").waitFor();
  await click(page, "Arrived at destination");
  await text(page, "Arrived Destination").waitFor();
  await click(page, "Complete trip");
  await click(page, "Confirm");
  await text(page, "Completed").waitFor();
  await text(page, "Payment: Pending").waitFor();
  await mkdir(".local-tools/offline/screenshots", { recursive: true });
  await page.screenshot({
    path: ".local-tools/offline/screenshots/completed-trip.png",
  });
  await back(page);
  await persona(page, "Supervisor - Demo Supervisor");
  await text(page, "Management").click();
  await text(page, "Audit").click();
  await text(
    page,
    "Most recent 200 audit entries in your organization, branch and airport scope.",
  ).waitFor();
  await page.screenshot({
    path: ".local-tools/offline/screenshots/supervisor.png",
  });
  contexts[0].phase = "reset";
  await click(page, "Reset offline demo");
  await click(page, "Reset practice data");
  await page
    .getByRole("button", { name: "Start Customer demo", exact: true })
    .waitFor();
  for (const [i, context] of contexts.entries()) {
    assert.deepEqual(context.blocked, [], apps[i] + " non-asset requests");
    assert.deepEqual(context.errors, [], apps[i] + " runtime errors");
  }
  console.log(
    "PASS offline four-role walkthrough: create -> dispatch -> checks -> OTP -> completion -> audit -> reset",
  );
  console.log(
    "PASS reload persistence; no backend/Firebase/internet requests; no JS runtime errors",
  );
} catch (error) {
  for (const [i, page] of pages.entries())
    console.error(
      apps[i] + " visible UI:\n" + (await read(page).catch(() => "(closed)")),
    );
  throw error;
} finally {
  for (const context of contexts) await context.close();
  await browser.close();
  await Promise.all(servers.map((s) => new Promise((done) => s.close(done))));
}
