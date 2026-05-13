#!/usr/bin/env node
/**
 * Seed mock data (coupons, exclusive deals) into Firestore.
 *
 * Usage:
 *   node scripts/seed_mock_data.mjs <service-account.json> [projectId]
 *
 * Requires a Firebase service account JSON file with Firestore read/write access.
 */

import { createSign } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const serviceAccountPath = process.argv[2];
const projectId = process.argv[3] ?? 'leastprice-yaser';
const databaseId = '(default)';

if (!serviceAccountPath) {
  console.error(
    'Usage: node scripts/seed_mock_data.mjs <service-account.json> [projectId]',
  );
  process.exit(1);
}

function base64UrlEncode(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function createJwt(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  signer.end();

  const signature = signer
    .sign(serviceAccount.private_key)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');

  return `${signingInput}.${signature}`;
}

async function fetchAccessToken(serviceAccount) {
  const assertion = createJwt(serviceAccount);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Token request failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

async function googleJson(url, accessToken, init = {}) {
  const response = await fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      ...(init.headers ?? {}),
    },
  });

  const text = await response.text();
  const data = text ? JSON.parse(text) : {};
  return { ok: response.ok, status: response.status, data };
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: value.toString() }
      : { doubleValue: value };
  }
  if (value instanceof Date || (value && typeof value.toISOString === 'function')) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((e) => toFirestoreValue(e)).filter((e) => e !== null),
      },
    };
  }
  if (typeof value === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value)
            .map(([k, v]) => [k, toFirestoreValue(v)])
            .filter(([, v]) => v !== null),
        ),
      },
    };
  }
  return null;
}

function daysFromNow(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

// ======================== COUPONS ========================

const coupons = [
  {
    docId: 'coupon-noon',
    code: 'EAST15',
    storeId: 'noon',
    storeName: 'Noon',
    discountLabel: '15% off',
    discountPercent: 15,
    expiresAt: daysFromNow(10),
    active: true,
    title: 'Exclusive Noon coupon',
    description: 'Copy the code and use it at checkout.',
  },
  {
    docId: 'coupon-namshi',
    code: 'STYLE20',
    storeId: 'namshi',
    storeName: 'Namshi',
    discountLabel: '20% off',
    discountPercent: 20,
    expiresAt: daysFromNow(7),
    active: true,
    title: 'Exclusive Namshi coupon',
    description: 'Save more on fashion and beauty orders.',
  },
  {
    docId: 'coupon-dar-al-amirat',
    code: 'F-URT3J',
    storeId: 'dar-al-amirat',
    storeName: 'Dar Al-Amirat',
    discountLabel: 'Extra discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Dar Al-Amirat coupon',
    description: 'Copy the code and use it at checkout for an extra discount.',
  },
  {
    docId: 'coupon-kabsh-najd',
    code: 'F-EMYFS',
    storeId: 'kabsh-najd',
    storeName: 'Kabsh Najd',
    discountLabel: 'Special offer',
    discountPercent: null,
    expiresAt: daysFromNow(30),
    active: true,
    title: 'Exclusive Kabsh Najd coupon',
    description: 'Save more on livestock and meat orders via the app.',
  },
  {
    docId: 'coupon-vanier',
    code: 'F-NEEM0',
    storeId: 'vanier',
    storeName: 'Vanier',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Vanier coupon',
    description: 'Discount code for skincare, makeup & perfume products.',
  },
  {
    docId: 'coupon-rashfa-dhikra',
    code: 'F-JWEJF',
    storeId: 'rashfa-dhikra',
    storeName: 'Rashfa Dhikra',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Rashfa Dhikra coupon',
    description: 'Discount code for perfumes.',
  },
  {
    docId: 'coupon-roshen',
    code: 'F-TKFG7',
    storeId: 'roshen',
    storeName: 'Roshen',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Roshen coupon',
    description: 'Discount code for clothing.',
  },
  {
    docId: 'coupon-roshen-tickets',
    code: 'F-Z3K4V',
    storeId: 'roshen-tickets',
    storeName: 'Roshen World Cup Tickets',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Roshen World Cup coupon',
    description: 'Discount code for World Cup tickets.',
  },
  {
    docId: 'coupon-al-reem',
    code: 'F-HZWMZ',
    storeId: 'al-reem',
    storeName: 'Al-Reem Abayas',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Al-Reem coupon',
    description: 'Discount code for abayas.',
  },
  {
    docId: 'coupon-vibe',
    code: 'F-ISGIW',
    storeId: 'vibe',
    storeName: 'Vibe',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Vibe coupon',
    description: 'Discount code for watches and accessories.',
  },
  {
    docId: 'coupon-qatret-asal',
    code: 'F-P3XPV',
    storeId: 'qatret-asal',
    storeName: 'Qatret Asal',
    discountLabel: 'Special discount',
    discountPercent: null,
    expiresAt: daysFromNow(60),
    active: true,
    title: 'Exclusive Qatret Asal coupon',
    description: 'Discount code for honey and natural products.',
  },
];

// ==================== EXCLUSIVE DEALS ====================

const exclusiveDeals = [
  {
    docId: 'mock_deal_1',
    title: 'عرض حصري على سامسونج جالكسي S24',
    imageUrl: 'https://example.com/samsung-s24.jpg',
    beforePrice: 5000,
    afterPrice: 4500,
    expiry_date: daysFromNow(7),
    active: true,
    dealUrl: 'https://panda.com.sa',
  },
  {
    docId: 'mock_deal_2',
    title: 'خصم 20% على منتجات أبل',
    imageUrl: 'https://example.com/apple-products.jpg',
    beforePrice: 3000,
    afterPrice: 2400,
    expiry_date: daysFromNow(5),
    active: true,
    dealUrl: 'https://extra.com',
  },
  {
    docId: 'dar_al_amirat_deal',
    title: 'دار الأميرات - أكبر تجمع لمنتجات العناية',
    imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc4033c8?q=80&w=1000&auto=format&fit=crop',
    beforePrice: 0,
    afterPrice: 0,
    expiry_date: daysFromNow(30),
    active: true,
    dealUrl: 'https://mtjr.at/FN2AIl2KWs',
  },
  {
    docId: 'kabsh_najd_deal',
    title: 'أضاحي كبش نجد - جودة ومصداقية',
    imageUrl: 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?q=80&w=1000&auto=format&fit=crop',
    beforePrice: 0,
    afterPrice: 0,
    expiry_date: daysFromNow(45),
    active: true,
    dealUrl: 'https://mtjr.at/_2-N8J8JYq',
  },
];

// ====================== SEED LOGIC =======================

function buildDocument(fields, docId) {
  // Remove docId from fields and map to Firestore values
  const { docId: _, ...data } = fields;
  const firestoreFields = Object.fromEntries(
    Object.entries(data)
      .map(([key, value]) => [key, toFirestoreValue(value)])
      .filter(([, value]) => value !== null),
  );
  return { fields: firestoreFields };
}

async function upsertDocument(accessToken, collection, docId, fields) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}` +
    `/documents/${collection}/${encodeURIComponent(docId)}`;

  const doc = buildDocument(fields, docId);
  const response = await googleJson(url, accessToken, {
    method: 'PATCH',
    body: JSON.stringify(doc),
  });

  if (!response.ok) {
    throw new Error(
      `Failed to upsert "${collection}/${docId}": ${JSON.stringify(response.data)}`,
    );
  }

  return response.data.name;
}

async function countDocuments(accessToken, collection) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}` +
    `/documents/${collection}?pageSize=1`;

  const response = await googleJson(url, accessToken);
  if (!response.ok) {
    if (response.status === 404) return 0;
    throw new Error(`Failed to list ${collection}: ${JSON.stringify(response.data)}`);
  }

  return Array.isArray(response.data.documents) ? response.data.documents.length : 0;
}

async function main() {
  const raw = await readFile(serviceAccountPath, 'utf8');
  const serviceAccount = JSON.parse(raw);
  const accessToken = await fetchAccessToken(serviceAccount);

  const results = { coupons: { seeded: 0 }, exclusiveDeals: { seeded: 0 } };

  // Seed coupons
  console.log('Seeding coupons...');
  for (const coupon of coupons) {
    const name = await upsertDocument(accessToken, 'coupons', coupon.docId, coupon);
    results.coupons.seeded++;
    console.log(`  + coupons/${coupon.docId}`);
  }

  // Seed exclusive deals
  console.log('Seeding exclusive deals...');
  for (const deal of exclusiveDeals) {
    const name = await upsertDocument(accessToken, 'exclusive_deals', deal.docId, deal);
    results.exclusiveDeals.seeded++;
    console.log(`  + exclusive_deals/${deal.docId}`);
  }

  // Verify counts
  const couponCount = await countDocuments(accessToken, 'coupons');
  const dealCount = await countDocuments(accessToken, 'exclusive_deals');

  console.log(
    JSON.stringify(
      {
        projectId,
        seeded: {
          coupons: results.coupons.seeded,
          exclusiveDeals: results.exclusiveDeals.seeded,
        },
        totalDocuments: {
          coupons: couponCount,
          exclusiveDeals: dealCount,
        },
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
