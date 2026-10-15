/* Real Firebase end-to-end: creates a temporary Firebase e-mail user, signs in to the running API
 * with its ID token (verified against Google's live certificates), then deletes everything again.
 *   FIREBASE_WEB_API_KEY=<web api key> npm run e2e:firebase     (API defaults to http://localhost:3000)
 * The web API key is a public identifier (it ships inside the app); it is read from the environment
 * only so this script does not hard-code it. */
const BASE = process.env.API || 'http://localhost:3000';
const KEY = process.env.FIREBASE_WEB_API_KEY;
if (!KEY) { console.error('Set FIREBASE_WEB_API_KEY.'); process.exit(2); }
const idt = (m, body) => fetch(`https://identitytoolkit.googleapis.com/v1/accounts:${m}?key=${KEY}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) }).then((r) => r.json());
const api = async (method, path, body, token) => {
  const r = await fetch(BASE + path, { method, headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) }, body: body ? JSON.stringify(body) : undefined });
  return { status: r.status, json: await r.json().catch(() => null) };
};
let n = 0;
const ok = (name, c, x = '') => { if (!c) throw new Error(`${name} ${x}`); console.log(`  ok ${++n}  ${name}`); };

(async () => {
  const email = `e2e-${Date.now()}@simtest.local`;
  const created = await idt('signUp', { email, password: 'gizli123', returnSecureToken: true });
  ok('Firebase creates the e-mail user', !!created.idToken, JSON.stringify(created.error));
  let account = null;
  try {
    const m = (await api('GET', '/auth/methods')).json;
    ok('server has Firebase e-mail and Google on, Apple and SMS off', m.firebase && m.email && m.google && !m.apple && !m.phone, JSON.stringify(m));
    ok('forged token is refused', (await api('POST', '/auth/firebase', { idToken: 'x'.repeat(40) })).status === 401);
    const first = (await api('POST', '/auth/firebase', { idToken: created.idToken })).json;
    ok('a new Firebase user is asked for a profile first', first.needsProfile === true);
    const s = (await api('POST', '/auth/firebase', { idToken: created.idToken, role: 'customer', name: 'E2E Firebase', phone: `0530${Math.floor(Math.random() * 9e6 + 1e6)}` })).json;
    account = s.account;
    ok('account is created from the verified token', account.email === email && account.signInProvider === 'password' && !!s.token);
    const again = (await api('POST', '/auth/firebase', { idToken: created.idToken })).json;
    ok('signing in again returns the same account', again.account.id === account.id);
    ok('the session works on protected routes', (await api('GET', '/auth/me', null, again.token)).json.id === account.id);
    const wrong = await idt('signInWithPassword', { email, password: 'yanlis', returnSecureToken: true });
    ok('Firebase refuses a wrong password', !!wrong.error);
    const reset = await idt('sendOobCode', { requestType: 'PASSWORD_RESET', email });
    ok('password reset mail request is accepted', reset.email === email, JSON.stringify(reset.error));
    console.log(`\nAll ${n} real-Firebase checks passed.`);
  } finally {
    if (account) await api('DELETE', `/privacy/account?accountId=${account.id}`, null, (await api('POST', '/auth/firebase', { idToken: created.idToken })).json?.token);
    await idt('delete', { idToken: created.idToken });
  }
})().catch((e) => { console.error('\nFAILED:', e.message); process.exit(1); });
