import test from 'node:test';
import assert from 'node:assert/strict';
import {parsePublicWebConfig,stagingProjectId} from './prepare-web-config.mjs';
const sample=()=>({AEROTRANS_ENV:'staging',FIREBASE_PROJECT_ID:stagingProjectId,
  API_BASE_URL:'https://review-api.example.invalid',FIREBASE_WEB_API_KEY:'test-only-public-placeholder',
  FIREBASE_WEB_APP_ID:'1:123:web:testfixture',FIREBASE_AUTH_DOMAIN:stagingProjectId+'.firebaseapp.com',
  FIREBASE_MESSAGING_SENDER_ID:'123'});
test('only complete public configuration for the approved test project is accepted',()=>{
  assert.equal(parsePublicWebConfig(JSON.stringify(sample())).FIREBASE_PROJECT_ID,stagingProjectId);
  for(const change of [{FIREBASE_PROJECT_ID:'airport-png-c866b'}, {API_BASE_URL:'http://localhost:8080'},
    {API_BASE_URL:'https://example.invalid/path'}, {API_BASE_URL:'https://user:password@example.invalid'},
    {FIREBASE_SERVICE_ACCOUNT_KEY:'never-for-the-client'}, {FIREBASE_WEB_APP_ID:''},
    {FIREBASE_AUTH_DOMAIN:'airport-png-c866b.firebaseapp.com'}]) {
    assert.throws(()=>parsePublicWebConfig(JSON.stringify({...sample(),...change})));
  }
});
