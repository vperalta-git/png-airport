// Optional check: uses an already installed Playwright and browser, never a runtime dependency.
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { resolve, extname, sep } from "node:path";
import assert from "node:assert/strict";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const apps = [
  "passenger_web",
  "control_room_web",
  "driver_mobile",
  "admin_web",
];
const servers = [];
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  for (const [index, app] of apps.entries()) {
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
        const mime = {
          ".html": "text/html",
          ".js": "application/javascript",
          ".mjs": "application/javascript",
          ".json": "application/json",
          ".wasm": "application/wasm",
          ".css": "text/css",
          ".png": "image/png",
        };
        res.setHeader(
          "Content-Type",
          mime[extname(file)] || "application/octet-stream",
        );
        res.end(await readFile(file));
      } catch {
        res.writeHead(404).end();
      }
    });
    await new Promise((ok, bad) => {
      server.once("error", bad);
      server.listen(5001 + index, "127.0.0.1", ok);
    });
    servers.push(server);
    const context = await browser.newContext();
    const external = [],
      errors = [];
    await context.route("**/*", (route) => {
      const url = new URL(route.request().url());
      // Static FlutterFire JS libraries are dependencies, not data/auth APIs.
      if (
        url.hostname === "www.gstatic.com" &&
        url.protocol === "https:" &&
        url.pathname.startsWith("/firebasejs/11.9.1/") &&
        url.pathname.endsWith(".js")
      )
        return route.continue();
      if (
        url.hostname === "fonts.gstatic.com" &&
        url.protocol === "https:" &&
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
    page.on("pageerror", (error) => errors.push(error.message));
    await page.goto("http://localhost:" + (5001 + index), {
      waitUntil: "load",
    });
    const semantics = page.locator("flt-semantics-placeholder");
    await semantics.waitFor({ state: "attached", timeout: 30000 });
    await semantics.evaluate((element) => element.click());
    try {
      await page
        .getByText("Local Firebase foundation is ready.", { exact: true })
        .waitFor({ timeout: 30000 });
    } catch (error) {
      throw new Error(
        app +
          ": " +
          (await page.locator("body").innerText()) +
          "; blocked=" +
          JSON.stringify(external) +
          "; errors=" +
          JSON.stringify(errors),
      );
    }
    assert.deepEqual(
      external,
      [],
      app + " attempted a non-local data/API request",
    );
    assert.deepEqual(errors, [], app + " browser errors");
    console.log(
      "PASS " +
        app +
        ": real Flutter startup/SDK configuration; no non-local data/API requests (static SDK/font downloads allowed)",
    );
    await context.close();
  }
} finally {
  await browser.close();
  await Promise.all(
    servers.map((server) => new Promise((done) => server.close(done))),
  );
}
