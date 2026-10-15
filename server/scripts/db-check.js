/* Read-only MongoDB diagnostics: `npm run db:check`.
 * Connects with MONGODB_URI from server/.env, names the likely cause when it fails,
 * and prints collection sizes plus the provider taxonomy actually in the database.
 * It never writes and never prints the URI or credentials. */
require('dotenv/config');
const mongoose = require('mongoose');

function classify(err) {
  const m = `${err.code ?? ''} ${err.name ?? ''} ${err.message ?? ''}`;
  if (/ENOTFOUND|EAI_AGAIN|querySrv|ECONNREFUSED.*53/i.test(m)) return 'DNS: the cluster host name could not be resolved (check the cluster address / internet).';
  if (/bad auth|Authentication failed|AuthenticationFailed|code: ?18/i.test(m)) return 'AUTH: user name or password was rejected (check the database user in Atlas).';
  if (/ssl|tls|certificate|alert number/i.test(m)) return 'TLS: the secure handshake failed (often Atlas Network Access blocks this IP, or a proxy intercepts TLS).';
  if (/ReplicaSetNoPrimary|Server selection timed out|ETIMEDOUT/i.test(m)) return 'NETWORK: server selection timed out. Most often Atlas > Network Access does not allow this machine\'s IP.';
  if (/Invalid scheme|Invalid connection string|URI/i.test(m)) return 'URI: the connection string is malformed.';
  if (/not authorized|requires authentication|Unauthorized/i.test(m)) return 'PERMISSIONS: the user can sign in but cannot read this database.';
  return 'UNKNOWN: ' + (err.message || err);
}

(async () => {
  const uri = process.env.MONGODB_URI;
  const dbName = process.env.DATABASE_NAME || 'usta';
  if (!uri) { console.error('MONGODB_URI is empty. Set it in server/.env.'); process.exit(2); }
  try {
    await mongoose.connect(uri, { dbName, serverSelectionTimeoutMS: 15000 });
    const db = mongoose.connection.db;
    console.log(`Connected. Database "${dbName}".`);
    const cols = await db.listCollections().toArray();
    for (const c of cols) {
      console.log(`- ${c.name}: ${await db.collection(c.name).estimatedDocumentCount()} documents`);
    }
    if (cols.some((c) => c.name === 'providers')) {
      const providers = db.collection('providers');
      const tax = await providers.aggregate([
        { $group: { _id: { mainType: '$mainType', subType: '$subType' }, n: { $sum: 1 } } },
        { $sort: { '_id.mainType': 1, n: -1 } },
      ]).toArray();
      console.log('Taxonomy (mainType / subType: count):');
      for (const t of tax) console.log(`  ${t._id.mainType} / ${t._id.subType}: ${t.n}`);
      const idx = await providers.indexes();
      console.log('Indexes:', idx.map((i) => i.name).join(', '));
    }
    await mongoose.disconnect();
  } catch (err) {
    console.error('Connection failed.\n  ' + classify(err));
    process.exit(1);
  }
})();
