import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

export const stagingProjectId = 'aerotrans-png-test-7d7128';
export function parsePublicWebConfig(raw) {
  let config;
  try { config = JSON.parse(raw); } catch { throw new Error('AEROTRANS_PUBLIC_CONFIG must be public Firebase/build JSON.'); }
  const fields = ['AEROTRANS_ENV','FIREBASE_PROJECT_ID','API_BASE_URL','FIREBASE_WEB_API_KEY',
    'FIREBASE_WEB_APP_ID','FIREBASE_AUTH_DOMAIN','FIREBASE_MESSAGING_SENDER_ID'];
  if (!config || typeof config !== 'object' || Array.isArray(config) ||
      Object.keys(config).some(key => !fields.includes(key)) ||
      fields.some(key => typeof config[key] !== 'string' || !config[key].trim() || config[key].includes('PRIVATE KEY'))) {
    throw new Error('Public web configuration has missing or unexpected fields. Never put a service account in it.');
  }
  if (config.AEROTRANS_ENV !== 'staging' || config.FIREBASE_PROJECT_ID !== stagingProjectId ||
      config.FIREBASE_AUTH_DOMAIN !== stagingProjectId + '.firebaseapp.com' ||
      !/^\d+$/.test(config.FIREBASE_MESSAGING_SENDER_ID) ||
      !config.FIREBASE_WEB_APP_ID.startsWith('1:' + config.FIREBASE_MESSAGING_SENDER_ID + ':web:')) {
    throw new Error('Only the separately approved Firebase test web app is supported.');
  }
  let url;
  try { url = new URL(config.API_BASE_URL); } catch { throw new Error('A valid HTTPS test API origin is required.'); }
  if (url.protocol !== 'https:' || url.origin !== config.API_BASE_URL ||
      ['localhost','127.0.0.1','10.0.2.2'].includes(url.hostname)) {
    throw new Error('The hosted test API must be an HTTPS origin without a path or credentials.');
  }
  return config;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const output = resolve(process.argv[2] || '.vercel/cache/public-web-defines.json');
  const config = parsePublicWebConfig(process.env.AEROTRANS_PUBLIC_CONFIG);
  mkdirSync(dirname(output), {recursive:true});
  writeFileSync(output, JSON.stringify(config), {mode:0o600});
  console.log('Public hosted-test configuration validated; server credentials are not included.');
}
