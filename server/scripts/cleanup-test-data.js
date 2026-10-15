/* Removes test data created while developing: `npm run db:cleanup-test [prefix]`.
 * Deletes only records whose owner id starts with the prefix (default "smoketest-") and providers
 * flagged `isDemo` by the mock sign-in. Everything else (the real listings) is untouched. */
require('dotenv/config');
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DATABASE_NAME || 'usta_db' });
  const db = mongoose.connection.db;
  const rx = new RegExp('^' + (process.argv[2] || 'smoketest-'));
  const convs = await db.collection('conversations').find({ customerId: rx }).toArray();
  const ids = convs.map((c) => c._id);
  const demoProviders = (await db.collection('providers').find({ isDemo: true }, { projection: { _id: 1 } }).toArray()).map((p) => String(p._id));
  const demoConvs = await db.collection('conversations').find({ providerId: { $in: demoProviders } }).toArray();
  const allIds = [...ids, ...demoConvs.map((c) => c._id)];
  const report = {
    messages: (await db.collection('messages').deleteMany({ conversationId: { $in: allIds } })).deletedCount,
    attachments: (await db.collection('attachments').deleteMany({ conversationId: { $in: allIds } })).deletedCount,
    conversations: (await db.collection('conversations').deleteMany({ _id: { $in: allIds } })).deletedCount,
    orders: (await db.collection('orders').deleteMany({ $or: [{ userId: rx }, { providerId: { $in: demoProviders } }] })).deletedCount,
    complaints: (await db.collection('complaints').deleteMany({ reporterId: rx })).deletedCount,
    accounts: (await db.collection('app_accounts').deleteMany({ $or: [{ _id: rx }, { providerId: { $in: demoProviders } }] })).deletedCount,
    demoProviders: (await db.collection('providers').deleteMany({ isDemo: true })).deletedCount,
  };
  console.log(report);
  await mongoose.disconnect();
})();
