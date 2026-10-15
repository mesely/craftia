import { randomBytes, scrypt, timingSafeEqual } from 'crypto';

const KEY_LENGTH = 64;

const derive = (password: string, salt: string): Promise<Buffer> =>
  new Promise((resolve, reject) =>
    scrypt(password, salt, KEY_LENGTH, { N: 16384, r: 8, p: 1 }, (err, key) => (err ? reject(err) : resolve(key))),
  );

export async function hashPassword(password: string): Promise<{ hash: string; salt: string }> {
  const salt = randomBytes(16).toString('hex');
  return { salt, hash: (await derive(password, salt)).toString('hex') };
}

export async function verifyPassword(password: string, salt: string, hash: string): Promise<boolean> {
  const expected = Buffer.from(hash, 'hex');
  const actual = await derive(password, salt);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}
