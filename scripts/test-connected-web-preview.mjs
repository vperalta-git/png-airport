// Optional browser acceptance using the existing local Playwright installation.
// A virtual public HTTPS origin exercises the compiled kIsWeb startup path.
import { createRequire } from 'node:module';
import { readFile, mkdir } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import assert from 'node:assert/strict';

const { chromium } = createRequire(import.meta.url)('playwright');
const base = resolve('apps/passenger_web/build/web');
const origin = 'https://aerotrans-preview.invalid';
const evidence = resolve('.local-tools/connected/web-preview');
const types = {'.html':'text/html','.js':'application/javascript','.mjs':'application/javascript',
  '.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.otf':'font/otf','.png':'image/png'};
const browser = await chromium.launch({channel:'msedge', headless:true});
const text = (page, label) => page.getByText(label)
  .or(page.getByLabel(label)).first();
await mkdir(evidence,{recursive:true});
try {
  for (const viewport of [{width:1440,height:1000},{width:390,height:844}]) {
    const context = await browser.newContext({viewport,serviceWorkers:'block'});
    const forbidden = [], errors = [];
    await context.route('**/*', async route => {
      const url = new URL(route.request().url());
      if (url.origin !== origin) {
        // Serve the engine's optional fallback font locally, never from Google.
        if (url.hostname === 'fonts.gstatic.com') {
          await route.fulfill({contentType:'font/ttf',body:await readFile(
            resolve('packages/png_transfer_flutter_core/fonts/Roboto-Regular.ttf'))});
          return;
        }
        forbidden.push(url.origin);
        await route.abort();
        return;
      }
      const file = resolve(base,'.' + decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname));
      assert.ok(file.startsWith(base + sep),'Static path escaped build directory');
      try {
        await route.fulfill({contentType:types[extname(file)] || 'application/octet-stream',body:await readFile(file)});
      } catch {
        await route.fulfill({status:404,body:'Not found'});
      }
    });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(origin);
    const semantics = page.locator('flt-semantics-placeholder');
    await semantics.waitFor({state:'attached',timeout:60000});
    await page.waitForTimeout(350);
    await semantics.evaluate(element => element.click());
    await text(page, /Airport transfers,/).waitFor();
    await page.mouse.move(viewport.width / 2, viewport.height / 2);
    if (viewport.width < 600) {
      await page.mouse.wheel(0, 420);
      await page.waitForTimeout(350);
    }
    await text(page, 'Online services awaiting configuration').waitFor();
    const signIn = page.getByRole('button',{name:'Sign-in unavailable',exact:true});
    await signIn.scrollIntoViewIfNeeded();
    assert.equal(await signIn.getAttribute('aria-disabled'),'true');
    await page.getByRole('button',{name:'Check service availability',exact:true}).click();
    await text(page, 'Online services awaiting configuration').waitFor();
    const labels = await page.locator('[aria-label]').evaluateAll(nodes =>
      nodes.map(node => node.getAttribute('aria-label')).join('\n'));
    assert.ok(!labels.includes('USB') && !labels.includes('An APK'),'Phone setup text leaked into public website');
    assert.deepEqual(forbidden,[],'Public website attempted API, Firebase or localhost access');
    assert.deepEqual(errors,[],'Browser runtime errors');
    await page.mouse.wheel(0,-3000);
    await page.waitForTimeout(250);
    await page.screenshot({path:resolve(evidence,`public-${viewport.width}.png`),fullPage:true});
    console.log(`PASS public website ${viewport.width}px: rendered, no localhost/Firebase calls, sign-in gated, retry safe`);
    await context.close();
  }
} finally {
  await browser.close();
}
