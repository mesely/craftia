/* End-to-end check of the running API, through real HTTP:
 *   npm run start   (in another terminal; DATA_SOURCE=mongo or mock)
 *   npm run e2e                      -> http://localhost:3000
 *   API=https://api.example.com npm run e2e
 * Creates accounts with @simtest.local e-mails and removes them again at the end (best effort:
 * `npm run db:cleanup-test` also clears anything left behind). Exit code 1 on the first failure. */
const BASE = process.env.API || 'http://localhost:3000';
const stamp = Date.now().toString(36);
const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
let step = 0;

async function call(method, path, { body, token, expect } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  let json = null;
  try { json = await res.json(); } catch { /* empty body */ }
  if (expect !== undefined && res.status !== expect) {
    throw new Error(`${method} ${path}: expected ${expect}, got ${res.status} ${JSON.stringify(json)}`);
  }
  return { status: res.status, json };
}
function ok(name, cond, extra = '') {
  step++;
  if (!cond) throw new Error(`#${step} ${name} ${extra}`);
  console.log(`  ok ${String(step).padStart(2)}  ${name}`);
}

(async () => {
  console.log(`E2E against ${BASE}`);
  const health = (await call('GET', '/health', { expect: 200 })).json;
  ok('health', health.status === 'ok', JSON.stringify(health));
  const methods = (await call('GET', '/auth/methods', { expect: 200 })).json;
  ok('password sign-in is on, federated ones are passive', methods.password === true && typeof methods.google === 'boolean');
  ok('federated sign-in answers 503 while switched off', methods.google || (await call('POST', '/auth/firebase', { body: { idToken: 'x'.repeat(30) } })).status === 503);
  const list = (await call('GET', '/providers?limit=5', { expect: 200 })).json;
  ok('public provider list works without a session', Array.isArray(list.items) && list.items.length > 0);
  ok('protected routes need a session', (await call('GET', '/service-requests?userId=x')).status === 401);

  const cust = (await call('POST', '/auth/register', { expect: 201, body: { role: 'customer', name: 'E2E Müşteri', phone: `0530${Math.floor(Math.random() * 9e6 + 1e6)}`, email: `cust-${stamp}@simtest.local`, password: 'gizli123' } })).json;
  ok('customer registers', !!cust.token && cust.account.role === 'customer');
  ok('the password never comes back', !JSON.stringify(cust).includes('gizli123') && !('passwordHash' in cust.account));
  ok('duplicate e-mail is refused', (await call('POST', '/auth/register', { body: { role: 'customer', name: 'Kopya', phone: '05301234500', email: `CUST-${stamp}@simtest.local`, password: 'gizli123' } })).status === 409);
  ok('wrong password is refused', (await call('POST', '/auth/login', { body: { identifier: cust.account.email, password: 'yanlis' } })).status === 401);
  const login = (await call('POST', '/auth/login', { expect: 201, body: { identifier: cust.account.email.toUpperCase(), password: 'gizli123' } })).json;
  ok('login by e-mail works', login.account.id === cust.account.id);
  const me = (await call('GET', '/auth/me', { token: login.token, expect: 200 })).json;
  ok('session identifies the person', me.id === cust.account.id);

  const ustaPhone = `0531${Math.floor(Math.random() * 9e6 + 1e6)}`;
  const usta = (await call('POST', '/auth/register', {
    expect: 201,
    body: {
      role: 'provider', name: 'E2E Usta', phone: ustaPhone, email: `usta-${stamp}@simtest.local`, password: 'gizli123',
      provider: { businessName: 'E2E Elektrik', phoneNumber: ustaPhone, mainType: 'TECHNICAL', subType: 'Elektrikçi', city: 'İzmir', district: 'Güzelbahçe', address: 'Maltepe Mah. 12. Sk. No:3', about: 'Güzelbahçe ve çevresinde elektrik tesisatı ve arıza bakımı yapıyorum.', lat: 38.3745, lng: 26.8912 },
    },
  })).json;
  ok('usta registers together with the listing', !!usta.account.providerId);
  const pid = usta.account.providerId;

  const page = (await call('GET', `/providers/${pid}`, { expect: 200 })).json;
  ok('listing is public and carries the coordinates', page.businessName === 'E2E Elektrik' && page.lat === 38.3745);
  const nearby = (await call('GET', `/providers?userLat=38.37&userLng=26.89&limit=50&subType=Elektrikçi`, { expect: 200 })).json;
  ok('listing shows up near its location', nearby.items.some((p) => p.id === pid));
  const hidden = (await call('GET', `/providers?userLat=38.37&userLng=26.89&limit=50&excludeId=${pid}`, { expect: 200 })).json;
  ok('an usta can exclude their own listing', !hidden.items.some((p) => p.id === pid));

  await call('POST', `/providers/${pid}/profile-photo`, { token: usta.token, expect: 201, body: { actorId: usta.account.id, contentType: 'image/png', data: png } });
  await call('POST', `/providers/${pid}/photos`, { token: usta.token, expect: 201, body: { actorId: usta.account.id, contentType: 'image/png', data: png } });
  await call('PATCH', `/providers/${pid}`, { token: usta.token, expect: 200, body: { actorId: usta.account.id, priceList: [{ serviceName: 'Priz değişimi', minPrice: 200, maxPrice: 300 }] } });
  const edited = (await call('GET', `/providers/${pid}`, { expect: 200 })).json;
  ok('profile photo, work photo and price list are saved', !!edited.profileImage && edited.portfolioImages.length === 1 && edited.priceList.length === 1);
  const photo = await fetch(BASE + edited.profileImage);
  ok('photos are served', photo.status === 200 && photo.headers.get('content-type').startsWith('image/'));
  ok("someone else cannot edit the usta's page", (await call('PATCH', `/providers/${pid}`, { token: cust.token, body: { actorId: cust.account.id, about: 'Ele geçirilmiş sayfa, ele geçirilmiş sayfa.' } })).status === 403);
  ok('nobody can act as somebody else', (await call('PATCH', `/providers/${pid}`, { token: cust.token, body: { actorId: usta.account.id, about: 'Ele geçirilmiş sayfa, ele geçirilmiş sayfa.' } })).status === 403);

  ok('an usta cannot send a request to their own page', (await call('POST', '/service-requests', { token: usta.token, body: { userId: usta.account.id, providerId: pid, mainType: 'TECHNICAL', subType: 'Elektrikçi', city: 'İzmir', description: 'Kendi sayfama talep.' } })).status === 400);
  const req = (await call('POST', '/service-requests', { token: cust.token, expect: 201, body: { userId: cust.account.id, customerName: 'E2E Müşteri', providerId: pid, mainType: 'TECHNICAL', subType: 'Elektrikçi', city: 'İzmir', description: 'Mutfaktaki priz çalışmıyor, bakar mısınız?', contactPhone: cust.account.phone } })).json;
  ok('request opens a conversation with the fixed first message', !!req.conversationId && req.lastMessageText.startsWith('Hizmet Talebi:'));
  const cid = req.conversationId;
  const inbox = (await call('GET', `/service-requests?providerId=${pid}`, { token: usta.token, expect: 200 })).json;
  ok('the usta sees it in the inbox', inbox.some((r) => r.id === req.id && r.unread === 1));
  ok("another customer cannot read the usta's inbox", (await call('GET', `/service-requests?providerId=${pid}`, { token: cust.token })).status === 403);

  const hi = (await call('POST', `/conversations/${cid}/messages`, { token: usta.token, expect: 201, body: { senderId: usta.account.id, text: 'Merhaba, yarın 10:00 uygun mu?' } })).json;
  const back = (await call('POST', `/conversations/${cid}/messages`, { token: cust.token, expect: 201, body: { senderId: cust.account.id, text: 'Evet uygun.', replyToId: hi.id } })).json;
  ok('both sides chat, with reply', back.replyToId === hi.id);
  await call('PATCH', `/messages/${back.id}`, { token: cust.token, expect: 200, body: { senderId: cust.account.id, text: 'Evet, uygun. Adresi yazıyorum.' } });
  ok("only the author edits a message", (await call('PATCH', `/messages/${back.id}`, { token: usta.token, body: { senderId: usta.account.id, text: 'hile' } })).status === 403);
  await call('POST', `/conversations/${cid}/attachments`, { token: cust.token, expect: 201, body: { senderId: cust.account.id, contentType: 'image/png', data: png } });
  const msgs = (await call('GET', `/conversations/${cid}/messages?viewerId=${cust.account.id}`, { token: cust.token, expect: 200 })).json;
  ok('messages list with edit and photo', msgs.length >= 3 && msgs.some((m) => m.editedAt));
  await call('DELETE', `/messages/${back.id}?senderId=${cust.account.id}`, { token: cust.token, expect: 200 });
  await call('POST', `/conversations/${cid}/read`, { token: usta.token, body: { viewerId: usta.account.id } });

  await call('PATCH', `/service-requests/${req.id}/status`, { token: usta.token, expect: 200, body: { status: 'ACCEPTED', actorId: usta.account.id } });
  await call('PATCH', `/service-requests/${req.id}/status`, { token: cust.token, expect: 200, body: { status: 'COMPLETED', actorId: cust.account.id } });
  const mine = (await call('GET', `/service-requests?userId=${cust.account.id}`, { token: cust.token, expect: 200 })).json;
  ok('status moves through accepted and completed', mine.find((r) => r.id === req.id).status === 'COMPLETED');

  const complaint = (await call('POST', '/complaints', { token: cust.token, expect: 201, body: { reporterId: cust.account.id, targetType: 'provider', targetId: pid, targetName: 'E2E Elektrik', reason: 'price_dispute', details: 'Test şikayeti.' } })).json;
  ok('a complaint gets a reference number', /\S+/.test(complaint.reference || ''));

  const dump = (await call('GET', `/privacy/export?accountId=${cust.account.id}`, { token: cust.token, expect: 200 })).json;
  ok('data export contains requests, messages and complaints', dump.serviceRequests.length === 1 && dump.conversations.length === 1 && dump.complaintsFiledByYou.length === 1);
  ok("nobody can export somebody else's data", (await call('GET', `/privacy/export?accountId=${usta.account.id}`, { token: cust.token })).status === 403);

  await call('DELETE', `/privacy/account?accountId=${cust.account.id}`, { token: cust.token, expect: 200 });
  ok('a deleted account cannot sign in again', (await call('POST', '/auth/login', { body: { identifier: cust.account.email, password: 'gizli123' } })).status === 401);
  await call('DELETE', `/privacy/account?accountId=${usta.account.id}`, { token: usta.token, expect: 200 });

  console.log(`\nAll ${step} checks passed.`);
  if (process.env.DATA_SOURCE === 'mongo' || process.env.CLEANUP === '1') {
    console.log('Run `npm run db:cleanup-test` to remove the test listing created by this run.');
  }
})().catch((e) => { console.error('\nE2E FAILED:', e.message); process.exit(1); });
