import { createSign } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const serviceAccountPath = process.argv[2];
const projectId = process.argv[3] ?? 'leastprice-yaser';
const databaseId = '(default)';

if (!serviceAccountPath) {
  console.error(
    'Usage: node scripts/seed_firestore_products.mjs <service-account.json> [projectId]',
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
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };
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
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
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
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === 'string') {
    return { stringValue: value };
  }

  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }

  if (typeof value === 'number') {
    if (Number.isInteger(value)) {
      return { integerValue: value.toString() };
    }

    return { doubleValue: value };
  }

  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value
          .map((entry) => toFirestoreValue(entry))
          .filter((entry) => entry !== null),
      },
    };
  }

  return {
    mapValue: {
      fields: Object.fromEntries(
        Object.entries(value)
          .map(([key, entry]) => [key, toFirestoreValue(entry)])
          .filter(([, entry]) => entry !== null),
      ),
    },
  };
}

function toFirestoreDocument(product) {
  const fields = Object.fromEntries(
    Object.entries(product)
      .filter(([key]) => key !== 'docId')
      .map(([key, value]) => [key, toFirestoreValue(value)])
      .filter(([, value]) => value !== null),
  );

  return { fields };
}

const products = [
  {
    docId: 'starter-dior-sauvage',
    category: 'عطور',
    categoryId: 'perfumes',
    expensiveName: 'Dior Sauvage Eau de Parfum',
    expensivePrice: 520,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1541643600914-78b084683601?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'بديل سافاج من نخبة العود',
    alternativePrice: 189,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
    rating: 4.9,
    reviewCount: 312,
    buyUrl: 'https://www.amazon.sa/s?k=sauvage+alternative',
    fragranceNotes: 'برغموت، أمبروكسان، فلفل',
    tags: ['عطور', 'رجالي', 'فاخر'],
  },
  {
    docId: 'baccarat-rouge-540',
    category: 'عطور',
    categoryId: 'perfumes',
    expensiveName: 'Baccarat Rouge 540',
    expensivePrice: 1210,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1523293182086-7651a899d37f?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'بديل بنفس الرائحة من العربية للعود',
    alternativePrice: 245,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&w=900&q=80',
    rating: 4.8,
    reviewCount: 204,
    buyUrl: 'https://www.noon.com/saudi-en/search?q=arabian+oud+perfume',
    fragranceNotes: 'زعفران، عنبر، ياسمين',
    tags: ['عطور', 'يونيسكس', 'أفضل قيمة'],
  },
  {
    docId: 'chanel-coco-mademoiselle',
    category: 'عطور',
    categoryId: 'perfumes',
    expensiveName: 'Chanel Coco Mademoiselle',
    expensivePrice: 615,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'بديل فلورال من إبراهيم القرشي',
    alternativePrice: 210,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1588405748880-12d1d2a59df9?auto=format&fit=crop&w=900&q=80',
    rating: 4.7,
    reviewCount: 177,
    buyUrl: 'https://www.amazon.sa/s?k=ibrahim+alqurashi+perfume',
    fragranceNotes: 'برتقال، ورد، مسك أبيض',
    tags: ['عطور', 'نسائي', 'أفضل قيمة'],
  },
  {
    docId: 'big-mac-khobar-burger',
    category: 'مطاعم',
    categoryId: 'restaurants',
    expensiveName: 'وجبة برجر مرجعية',
    expensivePrice: 26,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'برجر مدخن من مطعم برجر الشرقية - الخبر',
    alternativePrice: 18,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
    rating: 4.9,
    reviewCount: 278,
    buyUrl: 'https://www.hungerstation.com/sa-en',
    localLocationLabel: 'الخبر - طريق الأمير تركي - مطعم برجر الشرقية',
    localLocationUrl:
      'https://www.google.com/maps/search/?api=1&query=%D8%A8%D8%B1%D8%AC%D8%B1+%D8%A7%D9%84%D8%B4%D8%B1%D9%82%D9%8A%D8%A9+%D8%A7%D9%84%D8%AE%D8%A8%D8%B1',
    tags: ['مطاعم', 'برجر', 'الخبر'],
  },
  {
    docId: 'crispy-chicken-khobar',
    category: 'مطاعم',
    categoryId: 'restaurants',
    expensiveName: 'ساندوتش كرسبي مرجعي',
    expensivePrice: 24.5,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'كرسبي دجاج من مطعم أهل الخبر',
    alternativePrice: 16.5,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=900&q=80',
    rating: 4.7,
    reviewCount: 163,
    buyUrl: 'https://jahez.net',
    localLocationLabel: 'الخبر - حي الحزام الذهبي - مطعم أهل الخبر',
    localLocationUrl:
      'https://www.google.com/maps/search/?api=1&query=%D9%85%D8%B7%D8%B9%D9%85+%D8%A3%D9%87%D9%84+%D8%A7%D9%84%D8%AE%D8%A8%D8%B1',
    tags: ['مطاعم', 'دجاج', 'الخبر'],
  },
  {
    docId: 'iced-latte-local-cafe',
    category: 'مطاعم',
    categoryId: 'restaurants',
    expensiveName: 'آيس لاتيه مرجعي',
    expensivePrice: 21,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'آيس لاتيه من مقهى شرقي',
    alternativePrice: 13.5,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=900&q=80',
    rating: 4.8,
    reviewCount: 121,
    buyUrl: 'https://mrsool.co',
    localLocationLabel: 'الخبر - الكورنيش - مقهى شرقي',
    localLocationUrl:
      'https://www.google.com/maps/search/?api=1&query=%D9%85%D9%82%D9%87%D9%89+%D8%B4%D8%B1%D9%82%D9%8A+%D9%85%D8%AD%D9%84%D9%8A',
    tags: ['مطاعم', 'قهوة', 'مقهى'],
  },
  {
    docId: 'the-ordinary-niacinamide',
    category: 'تجميل',
    categoryId: 'cosmetics',
    expensiveName: 'The Ordinary Niacinamide 10% Serum',
    expensivePrice: 69,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'سيروم نياسيناميد من لاب سعودي',
    alternativePrice: 34,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1625772452859-1c03d5bf1137?auto=format&fit=crop&w=900&q=80',
    rating: 4.6,
    reviewCount: 143,
    buyUrl: 'https://www.noon.com/saudi-en/search?q=niacinamide+serum',
    activeIngredients: 'Niacinamide 10% + Zinc 1%',
    tags: ['تجميل', 'سيروم', 'نياسيناميد'],
  },
  {
    docId: 'la-roche-vitamin-c',
    category: 'تجميل',
    categoryId: 'cosmetics',
    expensiveName: 'La Roche-Posay Vitamin C Serum',
    expensivePrice: 220,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1570194065650-d99fb4d8a5c8?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'سيروم فيتامين C من براند سعودي للعناية',
    alternativePrice: 96,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
    rating: 4.5,
    reviewCount: 109,
    buyUrl: 'https://www.amazon.sa/s?k=vitamin+c+serum',
    activeIngredients: 'Vitamin C + Hyaluronic Acid',
    tags: ['تجميل', 'فيتامين سي', 'عناية بالبشرة'],
  },
  {
    docId: 'cerave-moisturizing-cream',
    category: 'صيدلية',
    categoryId: 'pharmacy',
    expensiveName: 'CeraVe Moisturizing Cream',
    expensivePrice: 89,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1556228578-dd6c36f7737d?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'مرطب اقتصادي من الصيدلية',
    alternativePrice: 44,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&w=900&q=80',
    rating: 4.7,
    reviewCount: 221,
    buyUrl: 'https://www.nahdionline.com',
    activeIngredients: 'Ceramides + Hyaluronic Acid',
    tags: ['صيدلية', 'مرطب', 'عناية'],
  },
  {
    docId: 'panadol-cold-flu',
    category: 'صيدلية',
    categoryId: 'pharmacy',
    expensiveName: 'Panadol Cold & Flu',
    expensivePrice: 24,
    expensiveImageUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80',
    alternativeName: 'خيار اقتصادي لنزلات البرد',
    alternativePrice: 14.5,
    alternativeImageUrl:
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=900&q=80',
    rating: 4.3,
    reviewCount: 75,
    buyUrl: 'https://www.al-dawaa.com',
    activeIngredients: 'Paracetamol + Decongestant',
    tags: ['صيدلية', 'برد', 'أدوية'],
  },
];

async function upsertProduct(accessToken, product) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}` +
    `/documents/products/${product.docId}`;

  const response = await googleJson(url, accessToken, {
    method: 'PATCH',
    body: JSON.stringify(toFirestoreDocument(product)),
  });

  if (!response.ok) {
    throw new Error(
      `Failed to upsert "${product.docId}": ${JSON.stringify(response.data)}`,
    );
  }

  return response.data.name;
}

async function listProducts(accessToken) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}` +
    '/documents/products?pageSize=100';

  const response = await googleJson(url, accessToken);
  if (!response.ok) {
    throw new Error(`Failed to list products: ${JSON.stringify(response.data)}`);
  }

  return Array.isArray(response.data.documents) ? response.data.documents : [];
}

async function main() {
  const raw = await readFile(serviceAccountPath, 'utf8');
  const serviceAccount = JSON.parse(raw);
  const accessToken = await fetchAccessToken(serviceAccount);

  const written = [];
  for (const product of products) {
    const documentName = await upsertProduct(accessToken, product);
    written.push(documentName);
  }

  const documents = await listProducts(accessToken);
  console.log(
    JSON.stringify(
      {
        projectId,
        seededProducts: products.length,
        totalDocumentsInProducts: documents.length,
        writtenDocuments: written,
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
