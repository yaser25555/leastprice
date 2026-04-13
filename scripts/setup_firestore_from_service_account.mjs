import { createSign } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const serviceAccountPath = process.argv[2];
const locationId = process.argv[3] ?? 'me-central2';
const databaseId = '(default)';

if (!serviceAccountPath) {
  console.error(
    'Usage: node scripts/setup_firestore_from_service_account.mjs <service-account.json> [locationId]',
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

async function waitForOperation(operationName, accessToken) {
  const operationUrl = `https://firestore.googleapis.com/v1/${operationName}`;

  for (let attempt = 0; attempt < 60; attempt += 1) {
    const response = await googleJson(operationUrl, accessToken);
    if (!response.ok) {
      throw new Error(`Operation polling failed: ${JSON.stringify(response.data)}`);
    }

    if (response.data.done) {
      if (response.data.error) {
        throw new Error(`Database creation failed: ${JSON.stringify(response.data.error)}`);
      }
      return response.data;
    }

    await new Promise((resolve) => setTimeout(resolve, 3000));
  }

  throw new Error('Timed out while waiting for Firestore database creation.');
}

function buildSeedDocument() {
  return {
    fields: {
      expensiveName: { stringValue: 'Dior Sauvage' },
      expensivePrice: { doubleValue: 520 },
      alternativeName: { stringValue: 'بديل سافاج من براند سعودي' },
      alternativePrice: { doubleValue: 189 },
      category: { stringValue: 'عطور' },
      rating: { doubleValue: 4.8 },
      buyUrl: { stringValue: 'https://example.com/leastprice-affiliate' },
    },
  };
}

async function ensureDatabase(accessToken, projectId) {
  const databaseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}`;
  const existing = await googleJson(databaseUrl, accessToken);

  if (existing.ok) {
    return { created: false, database: existing.data };
  }

  if (existing.status !== 404) {
    throw new Error(`Database check failed: ${JSON.stringify(existing.data)}`);
  }

  const createUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases?databaseId=${encodeURIComponent(databaseId)}`;
  const createResponse = await googleJson(createUrl, accessToken, {
    method: 'POST',
    body: JSON.stringify({
      locationId,
      type: 'FIRESTORE_NATIVE',
    }),
  });

  if (!createResponse.ok) {
    throw new Error(`Database creation request failed: ${JSON.stringify(createResponse.data)}`);
  }

  const operation = await waitForOperation(createResponse.data.name, accessToken);
  return {
    created: true,
    database: operation.response,
  };
}

async function ensureProductsSeed(accessToken, projectId) {
  const listUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}/documents/products?pageSize=1`;
  const listed = await googleJson(listUrl, accessToken);

  if (!listed.ok && listed.status !== 404) {
    throw new Error(`Collection read failed: ${JSON.stringify(listed.data)}`);
  }

  const existingDocuments = Array.isArray(listed.data.documents)
    ? listed.data.documents
    : [];

  if (existingDocuments.length > 0) {
    return {
      seeded: false,
      documentName: existingDocuments[0].name,
    };
  }

  const createDocumentUrl =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/${encodeURIComponent(databaseId)}/documents/products?documentId=starter-dior-sauvage`;
  const created = await googleJson(createDocumentUrl, accessToken, {
    method: 'POST',
    body: JSON.stringify(buildSeedDocument()),
  });

  if (!created.ok) {
    throw new Error(`Seed document creation failed: ${JSON.stringify(created.data)}`);
  }

  return {
    seeded: true,
    documentName: created.data.name,
  };
}

async function main() {
  const raw = await readFile(serviceAccountPath, 'utf8');
  const serviceAccount = JSON.parse(raw);
  const accessToken = await fetchAccessToken(serviceAccount);

  const databaseResult = await ensureDatabase(accessToken, serviceAccount.project_id);
  const seedResult = await ensureProductsSeed(accessToken, serviceAccount.project_id);

  console.log(
    JSON.stringify(
      {
        projectId: serviceAccount.project_id,
        databaseCreated: databaseResult.created,
        databaseName: databaseResult.database?.name,
        databaseLocation: databaseResult.database?.locationId,
        seededProductsCollection: seedResult.seeded,
        seedDocument: seedResult.documentName,
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
