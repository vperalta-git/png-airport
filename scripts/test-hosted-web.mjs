// Optional Playwright acceptance; use the existing local browser tools.
// This signs into isolated test accounts only and never prints credentials.
import { createRequire } from "node:module";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import assert from "node:assert/strict";
const { chromium } = createRequire(import.meta.url)("playwright");
const sheet = JSON.parse(
  readFileSync(".local-tools/hosted-test/accounts.json", "utf8"),
);
assert.equal(sheet.projectId, "aerotrans-png-test-7d7128");
const origin = "https://png-airport-kappa.vercel.app";
const apiOrigin = "https://aerotrans-png-test-api-7d7128.vercel.app";
const folder = resolve(".local-tools/hosted-test/browser");
mkdirSync(folder, { recursive: true });
const evidence = {
  origin,
  projectId: sheet.projectId,
  cases: [],
  success: false,
};
const save = () =>
  writeFileSync(
    resolve(folder, "results.json"),
    JSON.stringify(evidence, null, 2) + "\n",
  );
const browser = await chromium.launch({ channel: "msedge", headless: true });
let currentPage;
try {
  for (const [role, width] of [
    ["PASSENGER", 1440],
    ["DISPATCHER", 1440],
    ["DRIVER", 1440],
    ["SUPERVISOR", 1440],
    ["PASSENGER", 390],
  ]) {
    const account = sheet.accounts.find((a) => a.role === role);
    assert.ok(account);
    const context = await browser.newContext({
      viewport: { width, height: width === 390 ? 844 : 1000 },
      serviceWorkers: "block",
    });
    const page = await context.newPage();
    currentPage = page;
    const errors = [],
      responses = [],
      forbidden = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("request", (request) => {
      const url = new URL(request.url());
      if (
        ["localhost", "127.0.0.1", "10.0.2.2"].includes(url.hostname) ||
        url.hostname.includes("airport-png-c866b")
      )
        forbidden.push(url.origin);
    });
    page.on("response", (response) => {
      const url = new URL(response.url());
      if (url.origin === apiOrigin)
        responses.push({ path: url.pathname, status: response.status() });
    });
    await page.goto(origin, { waitUntil: "domcontentloaded" });
    const semantics = page.locator("flt-semantics-placeholder");
    await semantics.waitFor({ state: "attached", timeout: 60000 });
    await page.waitForTimeout(500);
    await semantics.evaluate((node) => node.click());
    await page
      .getByText("One platform. Four workspaces.", { exact: false })
      .first()
      .waitFor({ timeout: 60000 });
    // A driver selecting the supervisor card must still receive only driver access.
    const choice = role === "DRIVER" ? "SUPERVISOR" : role;
    const label = {
      PASSENGER: "Customer",
      DISPATCHER: "Control Room",
      SUPERVISOR: "Manager / Supervisor",
    }[choice];
    await page.getByText(label, { exact: false }).first().click();
    // Flutter swaps its text-editing element after focus; exercise real keyboard
    // entry rather than assigning the transient accessibility input's DOM value.
    await page.getByRole("textbox", { name: "Email", exact: true }).click();
    await page.waitForTimeout(200);
    await page.keyboard.insertText(account.email);
    await page.keyboard.press("Tab");
    await page.getByRole("textbox", { name: "Password", exact: true }).click();
    await page.waitForTimeout(200);
    await page.keyboard.insertText(account.password);
    await page.keyboard.press("Tab");
    await page.getByRole("button", { name: "Sign in", exact: true }).click();
    const title =
      "AeroTrans " +
      {
        PASSENGER: "Customer",
        DISPATCHER: "Control Room",
        DRIVER: "Driver",
        SUPERVISOR: "Supervisor",
      }[role];
    await page.getByText(title, { exact: true }).waitFor({ timeout: 60000 });
    await page
      .getByRole("button", { name: "Switch account", exact: true })
      .waitFor({ timeout: 60000 });
    const expected = [
      "/api/v1/bookings",
      "/api/v1/config",
      ...(["DISPATCHER", "SUPERVISOR"].includes(role)
        ? [
            "/api/v1/reports/dashboard",
            "/api/v1/resources/drivers",
            "/api/v1/resources/vehicles",
          ]
        : role === "DRIVER"
          ? ["/api/v1/resources/drivers"]
          : []),
    ];
    for (const path of expected)
      if (!responses.some((r) => r.path === path && r.status === 200))
        await page.waitForResponse(
          (response) =>
            response.url() === apiOrigin + path && response.status() === 200,
          { timeout: 30000 },
        );
    await page.waitForTimeout(500);
    assert.ok(
      responses.some((r) => r.path === "/api/v1/auth/me" && r.status === 200),
    );
    assert.deepEqual(
      forbidden,
      [],
      "Website contacted a local or live-project endpoint",
    );
    assert.deepEqual(errors, [], "Browser runtime error");
    assert.ok(
      responses.every((r) => r.status < 400),
      "A workspace API request failed",
    );
    await page.screenshot({
      path: resolve(folder, `${role.toLowerCase()}-${width}.png`),
      fullPage: true,
    });
    if (role === "SUPERVISOR") {
      await Promise.all([
        page.waitForResponse(
          (response) =>
            response.url() === apiOrigin + "/api/v1/users" &&
            response.status() === 200,
          { timeout: 30000 },
        ),
        // This pinned Flutter renderer omits bottom-navigation labels from its
        // browser semantics tree. Click the visible second destination at the
        // centre of its half of the fixed two-item navigation bar instead.
        page.mouse.click(width * 0.75, page.viewportSize().height - 40),
      ]);
      await page.waitForTimeout(500);
      assert.ok(
        responses.some((r) => r.path === "/api/v1/users" && r.status === 200),
      );
      await page.screenshot({
        path: resolve(folder, "supervisor-management.png"),
        fullPage: true,
      });
    }
    await page
      .getByRole("button", { name: "Switch account", exact: true })
      .click();
    await page.getByText("Choose your workspace", { exact: true }).waitFor();
    evidence.cases.push({
      role,
      width,
      success: true,
      backendProfileVerified: true,
      bookingsLoaded: true,
      accountSwitchPassed: true,
      forbiddenRequests: forbidden.length,
      runtimeErrors: errors.length,
    });
    save();
    console.log(
      `PASS hosted browser ${role} ${width}px: real login, authorized workspace, API data, account switch`,
    );
    await context.close();
  }
  evidence.success = true;
  evidence.completedAt = new Date().toISOString();
  save();
} catch (error) {
  evidence.failure = error.message;
  save();
  if (currentPage)
    await currentPage
      .screenshot({ path: resolve(folder, "failure.png"), fullPage: true })
      .catch(() => {});
  console.error("FAIL " + error.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
