const admin = require('firebase-admin');
const cheerio = require('cheerio');
const functionsV1 = require('firebase-functions/v1');
const logger = require('firebase-functions/logger');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const serverTimestamp = admin.firestore.FieldValue.serverTimestamp;
const increment = admin.firestore.FieldValue.increment;

const HYBRID_SEARCH_USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 LeastPriceBot/1.0';
const REQUEST_TIMEOUT_MS = 15000;
const MAX_RESULTS_PER_STORE = 8;
const MAX_TOTAL_RESULTS = 40;
const ALLOWED_CORS_HEADERS = 'Content-Type, X-SerpApi-Key, x-serpapi-key';
const ALLOWED_CORS_METHODS = 'GET, OPTIONS';
const SAUDI_FAMOUS_STORES_ONLY = true;

const PRIORITY_STORES = [
  {
    id: 'amazon',
    name: 'Amazon.sa',
    channelType: 'marketplace',
    hosts: ['amazon.sa', 'www.amazon.sa'],
    searchUrls: [],
  },
  {
    id: 'noon',
    name: 'Noon',
    channelType: 'marketplace',
    hosts: ['noon.com', 'www.noon.com'],
    searchUrls: [],
  },
  {
    id: 'hungerstation',
    name: 'HungerStation',
    channelType: 'delivery',
    hosts: ['hungerstation.com', 'www.hungerstation.com'],
    searchUrls: [
      (query) =>
        `https://hungerstation.com/sa-ar/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'panda',
    name: 'بنده',
    channelType: 'hypermarket',
    hosts: ['panda.sa', 'www.panda.sa'],
    searchUrls: [
      (query) => `https://www.panda.sa/ar/search?text=${encodeURIComponent(query)}`,
      (query) => `https://www.panda.sa/en/search?text=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'othaim',
    name: 'العثيم',
    channelType: 'hypermarket',
    hosts: ['othaimmarkets.com', 'www.othaimmarkets.com'],
    searchUrls: [
      (query) =>
        `https://www.othaimmarkets.com/ar-SA/search?q=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.othaimmarkets.com/en-US/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'almazraa',
    name: 'المزرعة',
    channelType: 'hypermarket',
    hosts: ['farm.com.sa', 'www.farm.com.sa'],
    searchUrls: [
      (query) => `https://www.farm.com.sa/ar/search?q=${encodeURIComponent(query)}`,
      (query) => `https://www.farm.com.sa/en/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'lulu',
    name: 'لولو',
    channelType: 'hypermarket',
    hosts: ['luluhypermarket.com', 'www.luluhypermarket.com'],
    searchUrls: [
      (query) =>
        `https://www.luluhypermarket.com/en-sa/search?q=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.luluhypermarket.com/ar-sa/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'carrefour',
    name: 'كارفور',
    channelType: 'hypermarket',
    hosts: ['carrefourksa.com', 'www.carrefourksa.com'],
    searchUrls: [
      (query) =>
        `https://www.carrefourksa.com/mafksa/en/search?text=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.carrefourksa.com/mafksa/ar/search?text=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'tamimi',
    name: 'التميمي',
    channelType: 'hypermarket',
    hosts: ['tamimimarkets.com', 'www.tamimimarkets.com'],
    searchUrls: [
      (query) =>
        `https://tamimimarkets.com/ar/search?type=product&q=${encodeURIComponent(query)}`,
      (query) =>
        `https://tamimimarkets.com/en/search?type=product&q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'toyou',
    name: 'تويو',
    channelType: 'delivery',
    hosts: ['toyou.io', 'www.toyou.io'],
    searchUrls: [
      (query) => `https://www.toyou.io/ar/search?q=${encodeURIComponent(query)}`,
      (query) => `https://www.toyou.io/en/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'keeta',
    name: 'كيتا',
    channelType: 'delivery',
    hosts: ['keeta.com', 'www.keeta.com'],
    searchUrls: [
      (query) => `https://www.keeta.com/sa-ar/search?q=${encodeURIComponent(query)}`,
      (query) => `https://www.keeta.com/sa-en/search?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'nahdi',
    name: 'النهدي',
    channelType: 'pharmacy',
    hosts: ['nahdionline.com', 'www.nahdionline.com'],
    searchUrls: [
      (query) =>
        `https://www.nahdionline.com/ar-sa/search?text=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.nahdionline.com/en-sa/search?text=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'aldawaa',
    name: 'صيدلية الدواء',
    channelType: 'pharmacy',
    hosts: ['al-dawaa.com', 'www.al-dawaa.com'],
    searchUrls: [
      (query) =>
        `https://www.al-dawaa.com/ara/search/result/?q=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.al-dawaa.com/eng/search/result/?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'jarir',
    name: 'جرير',
    channelType: 'electronics',
    hosts: ['jarir.com', 'www.jarir.com'],
    searchUrls: [
      (query) =>
        `https://www.jarir.com/sa-en/catalogsearch/result/?q=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.jarir.com/sa-ar/catalogsearch/result/?q=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'extra',
    name: 'إكسترا',
    channelType: 'electronics',
    hosts: ['extra.com', 'www.extra.com'],
    searchUrls: [
      (query) =>
        `https://www.extra.com/en-sa/search/?text=${encodeURIComponent(query)}`,
      (query) =>
        `https://www.extra.com/ar-sa/search/?text=${encodeURIComponent(query)}`,
    ],
  },
];

const STORE_BY_HOST = new Map();
for (const store of PRIORITY_STORES) {
  for (const host of store.hosts) {
    STORE_BY_HOST.set(host.toLowerCase(), store);
  }
}

exports.applyReferralRewardOnUserCreate = functionsV1
  .region('us-central1')
  .runWith({
    timeoutSeconds: 120,
    memory: '1GB',
    maxInstances: 10,
  })
  .firestore.document('users/{userId}')
  .onCreate(async (snapshot) => {
    const userRef = snapshot.ref;

    await db.runTransaction(async (transaction) => {
      const freshUserSnapshot = await transaction.get(userRef);
      if (!freshUserSnapshot.exists) {
        logger.warn('User document no longer exists before referral processing.', {
          userId: userRef.id,
        });
        return;
      }

      const userData = freshUserSnapshot.data() || {};
      const referralRewardApplied = userData.referralRewardApplied === true;
      if (referralRewardApplied) {
        logger.info('Referral reward already applied, skipping duplicate work.', {
          userId: userRef.id,
        });
        return;
      }

      const invitedBy = String(userData.invitedBy || '').trim().toUpperCase();
      if (!invitedBy) {
        transaction.set(
          userRef,
          {
            referralStatus: 'no_invite_code',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

      const referrerQuery = db
        .collection('users')
        .where('referralCode', '==', invitedBy)
        .limit(1);
      const referrerQuerySnapshot = await transaction.get(referrerQuery);
      if (referrerQuerySnapshot.empty) {
        transaction.set(
          userRef,
          {
            referralStatus: 'referrer_not_found',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        logger.warn('Invite code did not match any referrer.', {
          userId: userRef.id,
          invitedBy,
        });
        return;
      }

      const referrerSnapshot = referrerQuerySnapshot.docs[0];
      if (referrerSnapshot.id === userRef.id) {
        transaction.set(
          userRef,
          {
            invitedBy: '',
            referralStatus: 'self_referral_blocked',
            referralProcessedAt: serverTimestamp(),
          },
          { merge: true },
        );
        logger.warn('Blocked self-referral attempt.', {
          userId: userRef.id,
        });
        return;
      }

      transaction.set(
        referrerSnapshot.ref,
        {
          invitedCount: increment(1),
          updatedAt: serverTimestamp(),
        },
        { merge: true },
      );
      transaction.set(
        userRef,
        {
          referralRewardApplied: true,
          referralStatus: 'reward_applied',
          referralProcessedAt: serverTimestamp(),
          referrerUserId: referrerSnapshot.id,
        },
        { merge: true },
      );

      logger.info('Referral reward applied successfully.', {
        userId: userRef.id,
        referrerUserId: referrerSnapshot.id,
        invitedBy,
      });
    });
  });

exports.hybridMarketplaceSearch = functionsV1
  .region('us-central1')
  .runWith({
    timeoutSeconds: 120,
    memory: '1GB',
    maxInstances: 10,
  })
  .https.onRequest(async (request, response) => {
    applyCorsHeaders(request, response);

    if (request.method === 'OPTIONS') {
      response.status(204).send('');
      return;
    }

    if (request.method !== 'GET') {
      response.status(405).json({
        error: 'method-not-allowed',
        message: 'Use GET to search.',
      });
      return;
    }

    const query = String(request.query.q || '').trim();
    const location = String(request.query.location || 'Saudi Arabia').trim() || 'Saudi Arabia';
    const hl = String(request.query.hl || 'ar').trim().toLowerCase() === 'en' ? 'en' : 'ar';
    if (query.length < 2) {
      response.status(400).json({
        error: 'invalid-query',
        message: 'Query must contain at least 2 characters.',
      });
      return;
    }

    const serpApiKey = String(
      request.get('x-serpapi-key') || process.env.SERPAPI_KEY || '',
    ).trim();
    const dataForSeoLogin = String(process.env.DATAFORSEO_LOGIN || '').trim();
    const dataForSeoPassword = String(process.env.DATAFORSEO_PASSWORD || '').trim();
    const canUseDataForSeo = Boolean(dataForSeoLogin && dataForSeoPassword);
    const searchVertical = inferSearchVertical(query);
    const targetedStores = selectStoresForVertical(searchVertical);
    const scraperPromise = scrapePriorityStores(query, targetedStores);
    let dataForSeoResults = [];
    let serpApiResults = [];
    let scrapedResults = [];

    if (canUseDataForSeo) {
      try {
        dataForSeoResults = await searchDataForSeo(query, {
          location,
          hl,
          login: dataForSeoLogin,
          password: dataForSeoPassword,
        });
      } catch (error) {
        logger.warn('DataForSEO search failed inside hybridMarketplaceSearch.', {
          query,
          error: String(error),
        });
      }
    }

    // Keep SerpApi as a resilient fallback when DataForSEO is unavailable or empty.
    if (dataForSeoResults.length === 0 && serpApiKey) {
      try {
        serpApiResults = await searchSerpApi(query, serpApiKey, { location, hl });
      } catch (error) {
        logger.warn('SerpApi search failed inside hybridMarketplaceSearch.', {
          query,
          error: String(error),
        });
      }
    }

    try {
      scrapedResults = await scraperPromise;
    } catch (error) {
      logger.warn('HTML scraping failed inside hybridMarketplaceSearch.', {
        query,
        error: String(error),
      });
    }

    const mergedResults = mergeHybridSearchResults([
      ...dataForSeoResults,
      ...serpApiResults,
      ...scrapedResults,
    ]);
    const filteredResults = SAUDI_FAMOUS_STORES_ONLY
      ? filterToPriorityStores(mergedResults)
      : mergedResults;
    const finalResults = filteredResults.slice(0, MAX_TOTAL_RESULTS);

    response.status(200).json({
      query,
      vertical: searchVertical,
      targetedStores: targetedStores.map((store) => ({
        id: store.id,
        name: store.name,
        channelType: store.channelType,
      })),
      counts: {
        total: finalResults.length,
        dataforseo: dataForSeoResults.length,
        serpApi: serpApiResults.length,
        scraper: scrapedResults.length,
        hypermarket: finalResults.filter((item) => item.channelType === 'hypermarket')
          .length,
        delivery: finalResults.filter((item) => item.channelType === 'delivery')
          .length,
        pharmacy: finalResults.filter((item) => item.channelType === 'pharmacy')
          .length,
      },
      notice: buildHybridSearchNotice({
        dataForSeoResults,
        serpApiResults,
        scrapedResults,
      }),
      results: finalResults,
    });
  });

function applyCorsHeaders(request, response) {
  const origin = request.get('origin');
  response.set('Access-Control-Allow-Origin', origin || '*');
  response.set('Vary', 'Origin');
  response.set('Access-Control-Allow-Methods', ALLOWED_CORS_METHODS);
  response.set('Access-Control-Allow-Headers', ALLOWED_CORS_HEADERS);
  response.set('Access-Control-Max-Age', '3600');
}

async function searchSerpApi(query, apiKey, { location = 'Saudi Arabia', hl = 'ar' } = {}) {
  const url = new URL('https://serpapi.com/search.json');
  url.searchParams.set('engine', 'google_shopping');
  url.searchParams.set('q', query);
  url.searchParams.set('location', location);
  url.searchParams.set('gl', 'sa');
  url.searchParams.set('hl', hl);
  url.searchParams.set('api_key', apiKey);

  const payload = await fetchJson(url.toString());
  if (!payload || typeof payload !== 'object') {
    return [];
  }

  const candidates = [];
  const shoppingResults = Array.isArray(payload.shopping_results)
    ? payload.shopping_results
    : [];
  for (const item of shoppingResults) {
    const result = normalizeSerpApiResult(item);
    if (result) {
      candidates.push(result);
    }
  }

  const categorized = Array.isArray(payload.categorized_shopping_results)
    ? payload.categorized_shopping_results
    : [];
  for (const group of categorized) {
    const rows = Array.isArray(group?.shopping_results)
      ? group.shopping_results
      : [];
    for (const item of rows) {
      const result = normalizeSerpApiResult(item);
      if (result) {
        candidates.push(result);
      }
    }
  }

  return candidates;
}

async function searchDataForSeo(
  query,
  { location = 'Saudi Arabia', hl = 'ar', login, password } = {},
) {
  const endpoint = 'https://api.dataforseo.com/v3/serp/google/shopping/live/advanced';
  const payload = [
    {
      keyword: query,
      location_name: location,
      language_code: hl === 'en' ? 'en' : 'ar',
    },
  ];

  const response = await fetchJsonWithBasicAuth(endpoint, {
    login,
    password,
    body: payload,
  });
  if (!response || typeof response !== 'object') {
    return [];
  }

  const tasks = Array.isArray(response.tasks) ? response.tasks : [];
  const candidates = [];
  for (const task of tasks) {
    const resultBuckets = Array.isArray(task?.result) ? task.result : [];
    for (const bucket of resultBuckets) {
      const items = Array.isArray(bucket?.items) ? bucket.items : [];
      for (const item of items) {
        const result = normalizeDataForSeoResult(item);
        if (result) {
          candidates.push(result);
        }
      }
    }
  }

  return candidates;
}

function normalizeSerpApiResult(item) {
  if (!item || typeof item !== 'object') {
    return null;
  }

  const title = firstNonEmpty([
    item.title,
    item.product_title,
    item.name,
  ]);
  const productUrl = firstNonEmpty([
    item.product_link,
    item.link,
    item.url,
  ]);
  const imageUrl = firstNonEmpty([
    item.thumbnail,
    item.image,
    Array.isArray(item.thumbnails) ? item.thumbnails[0] : '',
  ]);

  const priceInfo = parsePriceValue(
    firstNonEmpty([
      item.price,
      item.extracted_price,
      item.price_value,
      item.raw_price,
    ]),
  );
  if (!title || !productUrl || priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const storeName = firstNonEmpty([
    item.source,
    item.seller,
    item.store_name,
    item.vendor,
  ]);
  const store = resolveStoreInfo({ storeName, productUrl });

  return {
    title: cleanProductTitle(title),
    priceValue: priceInfo.value,
    price: formatPriceLabel(priceInfo.value, priceInfo.currency),
    currency: priceInfo.currency,
    storeName: store.name || storeName || 'Online store',
    storeId: store.id,
    storeLogoUrl: buildStoreLogoUrl(store.host || productUrl),
    imageUrl: normalizeImageUrl(imageUrl),
    productUrl,
    sourceType: 'serpapi',
    channelType: store.channelType,
    isLiveDirect: false,
  };
}

function normalizeDataForSeoResult(item) {
  if (!item || typeof item !== 'object') {
    return null;
  }

  const title = firstNonEmpty([
    item.title,
    item.product_title,
    item.name,
  ]);
  const productUrl = firstNonEmpty([
    item.url,
    item.link,
    item.product_url,
    item.shop_ad_aclk,
  ]);
  const imageUrl = firstNonEmpty([
    item.image_url,
    item.thumbnail,
    item.image,
  ]);

  const priceInfo = parsePriceValue(
    firstNonEmpty([
      item.price?.current,
      item.price?.value,
      item.price,
      item.extracted_price,
      item.raw_price,
    ]),
  );
  if (!title || !productUrl || priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const storeName = firstNonEmpty([
    item.seller,
    item.merchant,
    item.source,
    item.shop,
  ]);
  const store = resolveStoreInfo({ storeName, productUrl });

  return {
    title: cleanProductTitle(title),
    priceValue: priceInfo.value,
    price: formatPriceLabel(priceInfo.value, priceInfo.currency),
    currency: priceInfo.currency,
    storeName: store.name || storeName || 'Online store',
    storeId: store.id,
    storeLogoUrl: buildStoreLogoUrl(store.host || productUrl),
    imageUrl: normalizeImageUrl(imageUrl),
    productUrl,
    sourceType: 'dataforseo',
    channelType: store.channelType,
    isLiveDirect: false,
  };
}

async function scrapePriorityStores(query, stores) {
  const settled = await Promise.allSettled(
    stores.map((store) => scrapeStoreSearchResults(store, query)),
  );
  const results = [];

  for (const outcome of settled) {
    if (outcome.status === 'fulfilled') {
      results.push(...outcome.value);
      continue;
    }

    logger.warn('A priority store scraper failed.', {
      error: String(outcome.reason),
    });
  }

  return results;
}

async function scrapeStoreSearchResults(store, query) {
  const collected = [];

  for (const buildSearchUrl of store.searchUrls) {
    const searchUrl = buildSearchUrl(query);
    if (!searchUrl) {
      continue;
    }

    try {
      const html = await fetchHtml(searchUrl);
      const parsed = extractStoreResultsFromHtml({
        html,
        store,
        searchUrl,
        query,
      });

      if (parsed.length > 0) {
        collected.push(...parsed);
        break;
      }
    } catch (error) {
      logger.warn('Store scraping request failed.', {
        storeId: store.id,
        query,
        url: searchUrl,
        error: String(error),
      });
    }
  }

  return mergeHybridSearchResults(collected).slice(0, MAX_RESULTS_PER_STORE);
}

function extractStoreResultsFromHtml({ html, store, searchUrl, query }) {
  const $ = cheerio.load(html);
  const results = [
    ...extractJsonLdResults($, store, searchUrl, query),
    ...extractEmbeddedJsonResults($, store, searchUrl, query),
    ...extractCardResults($, store, searchUrl, query),
  ];

  return mergeHybridSearchResults(results).slice(0, MAX_RESULTS_PER_STORE);
}

function extractJsonLdResults($, store, searchUrl, query) {
  const results = [];

  $('script[type="application/ld+json"]').each((_, element) => {
    const raw = $(element).contents().text().trim();
    if (!raw) {
      return;
    }

    const parsed = safeJsonParse(raw);
    if (!parsed) {
      return;
    }

    collectProductsFromJsonNode(parsed, (node) => {
      const result = buildScrapedResultFromNode(node, store, searchUrl, query);
      if (result) {
        results.push(result);
      }
    });
  });

  return results;
}

function extractEmbeddedJsonResults($, store, searchUrl, query) {
  const results = [];
  const scriptSelectors = [
    '#__NEXT_DATA__',
    '#__NUXT_DATA__',
    'script[data-rh="true"]',
  ];

  for (const selector of scriptSelectors) {
    $(selector).each((_, element) => {
      const raw = $(element).contents().text().trim();
      if (!raw) {
        return;
      }

      const parsed = safeJsonParse(raw);
      if (!parsed) {
        return;
      }

      collectProductsFromJsonNode(parsed, (node) => {
        const result = buildScrapedResultFromNode(node, store, searchUrl, query);
        if (result) {
          results.push(result);
        }
      });
    });
  }

  const inlineStatePatterns = [
    /__INITIAL_STATE__\s*=\s*(\{[\s\S]*?\});/g,
    /window\.__PRELOADED_STATE__\s*=\s*(\{[\s\S]*?\});/g,
  ];
  const allHtml = $.html();

  for (const pattern of inlineStatePatterns) {
    for (const match of allHtml.matchAll(pattern)) {
      const parsed = safeJsonParse(trimInlineJson(match[1]));
      if (!parsed) {
        continue;
      }

      collectProductsFromJsonNode(parsed, (node) => {
        const result = buildScrapedResultFromNode(node, store, searchUrl, query);
        if (result) {
          results.push(result);
        }
      });
    }
  }

  return results;
}

function extractCardResults($, store, searchUrl, query) {
  const results = [];
  const seenElements = new Set();
  const selectors = [
    '[data-product-id]',
    '.product-item',
    '.product',
    '.product-card',
    '.product-tile',
    '.product-grid-item',
    '.item.product',
    '.grid__item',
    '[class*="product"][class*="item"]',
  ];

  for (const selector of selectors) {
    $(selector)
      .slice(0, 80)
      .each((_, element) => {
        if (seenElements.has(element)) {
          return;
        }
        seenElements.add(element);

        const card = $(element);
        const result = buildScrapedResultFromCard(card, store, searchUrl, query);
        if (result) {
          results.push(result);
        }
      });
  }

  return results;
}

function buildScrapedResultFromCard(card, store, searchUrl, query) {
  const title = cleanProductTitle(
    firstNonEmpty([
      card.attr('data-name'),
      card.attr('data-product-name'),
      card.find('[itemprop="name"]').attr('content'),
      card.find('[itemprop="name"]').first().text(),
      card.find('[data-testid*="product-name"]').first().text(),
      card.find('[class*="product-name"]').first().text(),
      card.find('.product-item-name').first().text(),
      card.find('.name').first().text(),
      card.find('h2').first().text(),
      card.find('h3').first().text(),
      card.find('a[title]').attr('title'),
      card.find('img[alt]').attr('alt'),
    ]),
  );

  if (!title || !isRelevantToQuery(title, query)) {
    return null;
  }

  const priceInfo = parsePriceValue(
    firstNonEmpty([
      card.attr('data-price'),
      card.attr('data-product-price'),
      card.find('[itemprop="price"]').attr('content'),
      card.find('[data-price]').attr('data-price'),
      card.find('[class*="price"]').first().text(),
      card.find('.price').first().text(),
      card.find('.special-price').first().text(),
      card.text(),
    ]),
  );
  if (priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const productUrl = absoluteUrl(
    firstNonEmpty([
      card.attr('href'),
      card.find('a[href]').first().attr('href'),
    ]),
    searchUrl,
  );
  if (!productUrl) {
    return null;
  }

  const imageUrl = normalizeImageUrl(
    absoluteUrl(
      firstNonEmpty([
        card.find('img').first().attr('src'),
        card.find('img').first().attr('data-src'),
        card.find('img').first().attr('data-original'),
      ]),
      searchUrl,
    ),
  );

  return buildHybridSearchResult({
    title,
    priceValue: priceInfo.value,
    currency: priceInfo.currency,
    store,
    imageUrl,
    productUrl,
    sourceType: 'scraper',
    isLiveDirect: true,
  });
}

function buildScrapedResultFromNode(node, store, searchUrl, query) {
  if (!node || typeof node !== 'object') {
    return null;
  }

  const title = cleanProductTitle(
    firstNonEmpty([node.name, node.title, node.productName, node.label]),
  );
  if (!title || !isRelevantToQuery(title, query)) {
    return null;
  }

  const offers = node.offers || node.offer || node.priceSpecification || {};
  const priceInfo = parsePriceValue(
    firstNonEmpty([
      node.price,
      node.lowPrice,
      node.highPrice,
      node.finalPrice,
      node.currentPrice,
      node.salePrice,
      offers.price,
      offers.lowPrice,
      offers.highPrice,
      offers.value,
      node.priceFormatted,
    ]),
  );
  if (priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const productUrl = absoluteUrl(
    firstNonEmpty([
      node.url,
      node.link,
      node.productUrl,
      node.slug,
      node['@id'],
    ]),
    searchUrl,
  );
  if (!productUrl) {
    return null;
  }

  const imageUrl = normalizeImageUrl(
    absoluteUrl(
      extractImageValue(node.image || node.imageUrl || node.thumbnail),
      searchUrl,
    ),
  );

  return buildHybridSearchResult({
    title,
    priceValue: priceInfo.value,
    currency: priceInfo.currency,
    store,
    imageUrl,
    productUrl,
    sourceType: 'scraper',
    isLiveDirect: true,
  });
}

function buildHybridSearchResult({
  title,
  priceValue,
  currency,
  store,
  imageUrl,
  productUrl,
  sourceType,
  isLiveDirect,
}) {
  return {
    title,
    priceValue,
    price: formatPriceLabel(priceValue, currency),
    currency,
    storeName: store.name,
    storeId: store.id,
    storeLogoUrl: buildStoreLogoUrl(store.host || productUrl),
    imageUrl: imageUrl || '',
    productUrl,
    sourceType,
    channelType: store.channelType || 'other',
    isLiveDirect: Boolean(isLiveDirect),
  };
}

function buildHybridSearchNotice({ dataForSeoResults, serpApiResults, scrapedResults }) {
  if (scrapedResults.length > 0 && dataForSeoResults.length > 0) {
    return 'تم دمج نتائج DataForSEO مع الزحف المباشر من مواقع المتاجر المحلية.';
  }
  if (scrapedResults.length > 0 && serpApiResults.length > 0) {
    return 'تم دمج نتائج SerpApi مع الزحف المباشر من مواقع المتاجر المحلية.';
  }
  if (dataForSeoResults.length > 0) {
    return 'تم عرض نتائج DataForSEO حسب المدينة المحددة.';
  }
  if (scrapedResults.length > 0) {
    return 'تم عرض نتائج مباشرة من مواقع المتاجر الرسمية.';
  }
  if (serpApiResults.length > 0) {
    return 'تم عرض نتائج SerpApi، ولم يتوفر سحب HTML مباشر مناسب حالياً.';
  }
  return 'لم نجد نتائج مناسبة لهذا البحث حالياً.';
}

function mergeHybridSearchResults(results) {
  const deduped = new Map();

  for (const rawResult of results) {
    if (!rawResult || !rawResult.title || !rawResult.productUrl) {
      continue;
    }
    if (typeof rawResult.priceValue !== 'number' || rawResult.priceValue <= 0) {
      continue;
    }

    const fingerprint = [
      normalizeArabic(rawResult.title),
      rawResult.storeId || '',
      Number(rawResult.priceValue).toFixed(2),
    ].join('|');

    const existing = deduped.get(fingerprint);
    if (!existing) {
      deduped.set(fingerprint, rawResult);
      continue;
    }

    if (rawResult.isLiveDirect && !existing.isLiveDirect) {
      deduped.set(fingerprint, rawResult);
    }
  }

  return [...deduped.values()].sort((first, second) => {
    if (first.priceValue !== second.priceValue) {
      return first.priceValue - second.priceValue;
    }

    if (first.channelType !== second.channelType) {
      return channelOrder(first.channelType) - channelOrder(second.channelType);
    }

    if (first.isLiveDirect !== second.isLiveDirect) {
      return first.isLiveDirect ? -1 : 1;
    }

    return String(first.storeName).localeCompare(String(second.storeName), 'ar');
  });
}

function filterToPriorityStores(results) {
  const allowedStoreIds = new Set(PRIORITY_STORES.map((store) => store.id));
  return results.filter((item) => {
    const storeId = String(item?.storeId || '').trim().toLowerCase();
    if (allowedStoreIds.has(storeId)) {
      return true;
    }

    const host = extractHost(item?.productUrl || '');
    if (!host) {
      return false;
    }
    return STORE_BY_HOST.has(host.toLowerCase());
  });
}

function inferSearchVertical(query) {
  const normalized = normalizeArabic(query);
  const pharmacyHints = [
    'دواء',
    'صيدلية',
    'حبوب',
    'مسكن',
    'بانادول',
    'فيتامين',
    'مرطب',
    'كريم',
  ];
  const groceryHints = [
    'حليب',
    'خبز',
    'رز',
    'سكر',
    'عصير',
    'ماء',
    'قهوة',
    'شاي',
    'منظف',
    'حفاض',
    'بقالة',
    'مقاضي',
  ];
  const electronicsHints = [
    'جوال',
    'هاتف',
    'ايفون',
    'سامسونج',
    'شاحن',
    'كيبل',
    'سماعه',
    'لابتوب',
    'تابلت',
    'الكترونيات',
  ];
  const beautyHints = [
    'عطر',
    'عطور',
    'برفان',
    'مكياج',
    'كريم',
    'شامبو',
    'عنايه',
  ];
  const cafeHints = [
    'قهوه',
    'قهوة',
    'كافي',
    'كافيه',
    'اسبريسو',
    'لاتيه',
    'كابتشينو',
    'كوفي',
  ];

  if (pharmacyHints.some((hint) => normalized.includes(normalizeArabic(hint)))) {
    return 'pharmacy';
  }
  if (electronicsHints.some((hint) => normalized.includes(normalizeArabic(hint)))) {
    return 'electronics';
  }
  if (beautyHints.some((hint) => normalized.includes(normalizeArabic(hint)))) {
    return 'beauty';
  }
  if (cafeHints.some((hint) => normalized.includes(normalizeArabic(hint)))) {
    return 'cafe';
  }
  if (groceryHints.some((hint) => normalized.includes(normalizeArabic(hint)))) {
    return 'grocery';
  }
  return 'general';
}

function selectStoresForVertical(vertical) {
  switch (vertical) {
    case 'pharmacy':
      return PRIORITY_STORES.filter((store) =>
        ['pharmacy', 'marketplace'].includes(store.channelType),
      );
    case 'electronics':
      return PRIORITY_STORES.filter((store) =>
        ['electronics', 'marketplace'].includes(store.channelType),
      );
    case 'beauty':
      return PRIORITY_STORES.filter((store) =>
        ['pharmacy', 'hypermarket', 'marketplace'].includes(store.channelType),
      );
    case 'cafe':
      return PRIORITY_STORES.filter((store) =>
        ['delivery', 'hypermarket'].includes(store.channelType),
      );
    case 'grocery':
      return PRIORITY_STORES.filter((store) =>
        ['hypermarket', 'delivery'].includes(store.channelType),
      );
    default:
      return PRIORITY_STORES.filter((store) =>
        ['hypermarket', 'pharmacy', 'delivery', 'electronics', 'marketplace'].includes(
          store.channelType,
        ),
      );
  }
}

function resolveStoreInfo({ storeName, productUrl }) {
  const host = extractHost(productUrl);
  const byHost = host ? STORE_BY_HOST.get(host.toLowerCase()) : null;
  if (byHost) {
    return {
      id: byHost.id,
      name: byHost.name,
      host: host.toLowerCase(),
      channelType: byHost.channelType,
    };
  }

  const normalizedStoreName = normalizeArabic(storeName || '');
  for (const store of PRIORITY_STORES) {
    if (normalizedStoreName.includes(normalizeArabic(store.name))) {
      return {
        id: store.id,
        name: store.name,
        host: store.hosts[0],
        channelType: store.channelType,
      };
    }
  }

  return {
    id: host ? host.replace(/^www\./, '') : 'unknown',
    name: storeName || host || 'Online store',
    host,
    channelType: 'other',
  };
}

function buildStoreLogoUrl(hostOrUrl) {
  const host = extractHost(hostOrUrl);
  if (!host) {
    return '';
  }

  const url = new URL('https://www.google.com/s2/favicons');
  url.searchParams.set('sz', '128');
  url.searchParams.set('domain_url', `https://${host}`);
  return url.toString();
}

function collectProductsFromJsonNode(node, visitor) {
  if (!node) {
    return;
  }

  if (Array.isArray(node)) {
    for (const item of node) {
      collectProductsFromJsonNode(item, visitor);
    }
    return;
  }

  if (typeof node !== 'object') {
    return;
  }

  const type = String(node['@type'] || '').toLowerCase();
  const hasProductSignals =
    type.includes('product') ||
    (node.name || node.title) &&
      (node.price || node.lowPrice || node.offers || node.priceSpecification);

  if (hasProductSignals) {
    visitor(node);
  }

  for (const value of Object.values(node)) {
    collectProductsFromJsonNode(value, visitor);
  }
}

function isRelevantToQuery(title, query) {
  const normalizedTitle = normalizeArabic(title);
  const tokens = normalizeArabic(query)
    .split(/\s+/)
    .map((token) => token.trim())
    .filter((token) => token.length >= 2);

  if (tokens.length === 0) {
    return true;
  }

  return tokens.some((token) => normalizedTitle.includes(token));
}

function cleanProductTitle(title) {
  const raw = String(title || '').replace(/\s+/g, ' ').trim();
  if (!raw) {
    return '';
  }

  const separators = [' | ', ' - ', ' – ', ' — ', ' • '];
  for (const separator of separators) {
    const index = raw.indexOf(separator);
    if (index > 12) {
      return raw.slice(0, index).trim();
    }
  }

  return raw;
}

function parsePriceValue(value) {
  if (value == null) {
    return { value: null, currency: 'SAR' };
  }

  if (typeof value === 'number' && Number.isFinite(value)) {
    return { value, currency: 'SAR' };
  }

  const normalized = normalizeDigits(String(value))
    .replace(/&nbsp;/gi, ' ')
    .replace(/[,،]/g, '')
    .trim();
  if (!normalized) {
    return { value: null, currency: 'SAR' };
  }

  const currency = /(SAR|ريال|ر\.?\s?س)/i.test(normalized) ? 'SAR' : 'SAR';
  const match = normalized.match(/([0-9]+(?:\.[0-9]{1,2})?)/);
  if (!match) {
    return { value: null, currency };
  }

  const parsed = Number.parseFloat(match[1]);
  return {
    value: Number.isFinite(parsed) ? parsed : null,
    currency,
  };
}

function formatPriceLabel(value, currency) {
  const normalizedCurrency = currency || 'SAR';
  return `${formatAmount(value)} ${normalizedCurrency}`;
}

function formatAmount(value) {
  return Number.isInteger(value) ? value.toFixed(0) : value.toFixed(2);
}

function normalizeDigits(value) {
  const easternArabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  return String(value || '').replace(/[٠-٩]/g, (digit) => easternArabicDigits[digit]);
}

function normalizeArabic(value) {
  return normalizeDigits(String(value || ''))
    .toLowerCase()
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function firstNonEmpty(values) {
  for (const value of values) {
    if (Array.isArray(value)) {
      const nested = firstNonEmpty(value);
      if (nested) {
        return nested;
      }
      continue;
    }

    if (value == null) {
      continue;
    }

    const text = String(value).trim();
    if (text) {
      return text;
    }
  }
  return '';
}

function extractImageValue(value) {
  if (!value) {
    return '';
  }

  if (Array.isArray(value)) {
    return extractImageValue(value[0]);
  }

  if (typeof value === 'object') {
    return firstNonEmpty([value.url, value.contentUrl, value.src]);
  }

  return String(value);
}

function absoluteUrl(value, baseUrl) {
  const text = String(value || '').trim();
  if (!text) {
    return '';
  }

  try {
    return new URL(text, baseUrl).toString();
  } catch (_) {
    return '';
  }
}

function normalizeImageUrl(value) {
  const text = String(value || '').trim();
  if (!text) {
    return '';
  }

  if (text.startsWith('//')) {
    return `https:${text}`;
  }

  return text;
}

function extractHost(value) {
  const text = String(value || '').trim();
  if (!text) {
    return '';
  }

  try {
    return new URL(text).host;
  } catch (_) {
    try {
      return new URL(`https://${text}`).host;
    } catch (_) {
      return '';
    }
  }
}

function channelOrder(channelType) {
  switch (channelType) {
    case 'hypermarket':
      return 0;
    case 'delivery':
      return 1;
    case 'pharmacy':
      return 2;
    case 'electronics':
      return 3;
    case 'marketplace':
      return 4;
    default:
      return 5;
  }
}

async function fetchJson(url) {
  const response = await fetchWithTimeout(url, {
    headers: {
      accept: 'application/json, text/plain, */*',
      'user-agent': HYBRID_SEARCH_USER_AGENT,
    },
  });
  if (!response.ok) {
    throw new Error(`Request failed with ${response.status} for ${url}`);
  }
  return response.json();
}

async function fetchJsonWithBasicAuth(
  url,
  { login, password, body },
) {
  const credentials = Buffer.from(`${login}:${password}`).toString('base64');
  const response = await fetchWithTimeout(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      accept: 'application/json, text/plain, */*',
      'content-type': 'application/json',
      'user-agent': HYBRID_SEARCH_USER_AGENT,
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Request failed with ${response.status} for ${url}`);
  }
  return response.json();
}

async function fetchHtml(url) {
  const response = await fetchWithTimeout(url, {
    headers: {
      accept:
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'accept-language': 'ar-SA,ar;q=0.9,en;q=0.8',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
      'user-agent': HYBRID_SEARCH_USER_AGENT,
    },
  });
  if (!response.ok) {
    throw new Error(`HTML request failed with ${response.status} for ${url}`);
  }
  return response.text();
}

async function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    return await fetch(url, {
      redirect: 'follow',
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }
}

function safeJsonParse(value) {
  try {
    return JSON.parse(value);
  } catch (_) {
    return null;
  }
}

function trimInlineJson(value) {
  return String(value || '').trim().replace(/;$/, '');
}
