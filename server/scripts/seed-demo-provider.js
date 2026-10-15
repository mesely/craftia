/* Fills in one listing so the interface can be tested with a complete page:
 *   npm run db:seed-demo -- <providerId>
 * Sets the service type, introduction, a profile photo, four work photos and a few reviews.
 * Photos are read from seed-media/ (kept out of git: they are the usta's own photos).
 * Safe to run again (it replaces its own records). */
require('dotenv/config');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const providerId = process.argv[2];
if (!providerId || !/^[a-f\d]{24}$/i.test(providerId)) {
  console.error('Usage: npm run db:seed-demo -- <24-char providerId>');
  process.exit(1);
}

const media = (name) => fs.readFileSync(path.join(__dirname, '..', 'seed-media', name)).toString('base64');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DATABASE_NAME || 'usta_db' });
  const db = mongoose.connection.db;
  const providers = db.collection('providers');
  const attachments = db.collection('attachments');
  const reviews = db.collection('reviews');
  const _id = new mongoose.Types.ObjectId(providerId);
  const doc = await providers.findOne({ _id });
  if (!doc) throw new Error('Provider not found');

  await attachments.deleteMany({ ownerId: `seed-${providerId}` });
  const save = async (file) => {
    const data = media(file);
    const id = new mongoose.Types.ObjectId().toString();
    await attachments.insertOne({
      _id: id, conversationId: null, ownerId: `seed-${providerId}`, contentType: 'image/jpeg',
      data, size: Math.floor((data.length * 3) / 4), createdAt: new Date().toISOString(),
    });
    return `/attachments/${id}`;
  };
  const profileImage = await save('lutfi-portre.jpg');
  const portfolioImages = [];
  for (const f of fs.readdirSync(path.join(__dirname, '..', 'seed-media')).filter((n) => n.endsWith('.jpg') && n !== 'lutfi-portre.jpg').sort()) {
    portfolioImages.push(await save(f));
  }

  await reviews.deleteMany({ orderId: new RegExp(`^seed-${providerId}-`) });
  const now = Date.now();
  const sample = [
    ['Tuncay K.', 5, 'Sigorta panosunu aynı gün yeniledi, çok temiz iş çıkardı.'],
    ['Ahmet D.', 4.5, 'Zamanında geldi, fiyatı baştan net söyledi. Tavsiye ederim.'],
  ];
  await reviews.insertMany(sample.map(([authorName, rating, comment], i) => ({
    orderId: `seed-${providerId}-${i + 1}`, userId: `seed-${providerId}`, providerId, authorName, rating, comment,
    tags: [], createdAt: new Date(now - (i + 1) * 9 * 86400000), updatedAt: new Date(now - (i + 1) * 9 * 86400000),
  })));
  const avg = Math.round((sample.reduce((s, r) => s + r[1], 0) / sample.length) * 10) / 10;

  await providers.updateOne({ _id }, { $set: {
    mainType: 'TECHNICAL',
    subType: 'elektrikçi',
    about: 'Güzelbahçe ve çevresinde 15 yıldır elektrik tesisatı, sigorta panosu yenileme, aydınlatma ve arıza bakımı yapıyorum. Keşif ücretsiz, fiyatı işe başlamadan netleştiririm.',
    profileImage,
    portfolioImages,
    aiVerified: true,
    rating: avg,
    reviewCount: sample.length,
    lat: 38.3745,
    lng: 26.8912,
    serviceAreas: [],
  } });
  console.log({ profileImage, portfolioImages: portfolioImages.length, rating: avg, reviews: sample.length });
  await mongoose.disconnect();
})();
