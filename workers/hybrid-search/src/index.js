import * as cheerio from 'cheerio';

const HYBRID_SEARCH_USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 LeastPriceBot/1.0';
const REQUEST_TIMEOUT_MS = 8000;
const MAX_RESULTS_PER_STORE = 8;
const MAX_TOTAL_RESULTS = 40;
const ALLOWED_CORS_HEADERS = 'Content-Type, X-SerpApi-Key, x-serpapi-key, X-Serper-Key, x-serper-key';
const ALLOWED_CORS_METHODS = 'GET, OPTIONS';
const SAUDI_FAMOUS_STORES_ONLY = false;

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
    id: 'namshi',
    name: 'نمشي',
    channelType: 'marketplace',
    hosts: ['namshi.com', 'www.namshi.com', 'en-sa.namshi.com', 'ar-sa.namshi.com'],
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
    hosts: ['panda.com.sa', 'panda.sa', 'www.panda.com.sa', 'www.panda.sa'],
    searchUrls: [
      (query) => `https://www.panda.com.sa/ar/search?q=${encodeURIComponent(query)}`,
      (query) => `https://www.panda.com.sa/ar/search?text=${encodeURIComponent(query)}`,
    ],
  },
  {
    id: 'othaim',
    name: 'العثيم',
    channelType: 'hypermarket',
    hosts: ['othaimmarkets.com', 'www.othaimmarkets.com'],
    searchUrls: [
      (query) =>
        `https://www.othaimmarkets.com/catalogsearch/result/?q=${encodeURIComponent(query)}`,
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
  {
    id: 'danube',
    name: 'الدانوب',
    channelType: 'hypermarket',
    hosts: ['danube.sa', 'www.danube.sa'],
    searchUrls: [],
  },
  {
    id: 'bindawood',
    name: 'بن داود',
    channelType: 'hypermarket',
    hosts: ['bindawood.com', 'www.bindawood.com'],
    searchUrls: [],
  },
  {
    id: 'ikea',
    name: 'ايكيا',
    channelType: 'electronics',
    hosts: ['ikea.com.sa', 'www.ikea.com.sa'],
    searchUrls: [],
  },
  {
    id: 'saco',
    name: 'ساكو',
    channelType: 'electronics',
    hosts: ['saco.sa', 'www.saco.sa'],
    searchUrls: [],
  },
  {
    id: 'niceone',
    name: 'نايس ون',
    channelType: 'marketplace',
    hosts: ['niceonesa.com', 'www.niceonesa.com'],
    searchUrls: [],
  },
  {
    id: 'goldenscent',
    name: 'قولدن سنت',
    channelType: 'marketplace',
    hosts: ['goldenscent.com', 'www.goldenscent.com'],
    searchUrls: [],
  },
  {
    id: 'abyat',
    name: 'ابيات',
    channelType: 'electronics',
    hosts: ['abyat.com', 'www.abyat.com'],
    searchUrls: [],
  },
  {
    id: 'homecentre',
    name: 'هوم سنتر',
    channelType: 'electronics',
    hosts: ['homecentre.com', 'www.homecentre.com'],
    searchUrls: [],
  },
];

const STORE_BY_HOST = new Map();
for (const store of PRIORITY_STORES) {
  for (const host of store.hosts) {
    STORE_BY_HOST.set(host.toLowerCase(), store);
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (
      url.pathname !== '/' &&
      url.pathname !== '/api/hybridMarketplaceSearch' &&
      url.pathname !== '/hybridMarketplaceSearch'
    ) {
      return jsonResponse(
        { error: 'not-found', message: 'Use the root Worker URL for search.' },
        404,
        request,
      );
    }

    if (request.method === 'OPTIONS') {
      return new Response('', {
        status: 204,
        headers: buildCorsHeaders(request),
      });
    }

    if (request.method !== 'GET') {
      return jsonResponse(
        { error: 'method-not-allowed', message: 'Use GET to search.' },
        405,
        request,
      );
    }

    const query = String(url.searchParams.get('q') || '').trim();
    const location =
      String(url.searchParams.get('location') || 'Saudi Arabia').trim() ||
      'Saudi Arabia';
    const hl =
      String(url.searchParams.get('hl') || 'ar').trim().toLowerCase() === 'en'
        ? 'en'
        : 'ar';
    const requestedStoreId = String(url.searchParams.get('store') || '')
      .trim()
      .toLowerCase();

    if (!url.searchParams.has('q') && (url.pathname === '/' || url.pathname === '')) {
      return jsonResponse(
        { status: 'ok', message: 'LeastPrice Search Worker is running smoothly.' },
        200,
        request,
      );
    }

    if (query.length < 2) {
      return jsonResponse(
        { error: 'invalid-query', message: 'Query must contain at least 2 characters.' },
        400,
        request,
      );
    }

    const serpApiKey = String(
      request.headers.get('x-serpapi-key') || env.SERPAPI_KEY || '',
    ).trim();
    const serperApiKey = String(
      request.headers.get('x-serper-key') || env.SERPER_KEY || env.SERPER_API_KEY || '',
    ).trim();
    const dataForSeoLogin = String(env.DATAFORSEO_LOGIN || '').trim();
    const dataForSeoPassword = String(env.DATAFORSEO_PASSWORD || '').trim();
    const canUseDataForSeo = Boolean(dataForSeoLogin && dataForSeoPassword);
    const searchVertical = inferSearchVertical(query);
    const targetedStores = selectStoresForSearch(searchVertical, requestedStoreId);

    // For Shopping APIs, 'site:' operator often breaks results. 
    // We'll use the clean query for APIs and filter locally, 
    // but we'll keep the site-specific query for the general search fallback.
    const effectiveApiQuery = query;
    let siteSpecificQuery = query;
    if (requestedStoreId) {
      const requestedStore = PRIORITY_STORES.find(s => s.id === requestedStoreId.toLowerCase());
      if (requestedStore && requestedStore.hosts && requestedStore.hosts.length > 0) {
        siteSpecificQuery = `site:${requestedStore.hosts[0]} ${query}`;
      }
    }

    // Limit scraping to top 6 stores to improve speed
    const storesToScrape = targetedStores.slice(0, 6);

    let dataForSeoResults = [];
    let serpApiResults = [];
    let serperResults = [];
    let scrapedResults = [];

    const scraperPromise = scrapePriorityStores(query, storesToScrape);

    // Run APIs in parallel for better speed if we have multiple keys
    const apiPromises = [];

    if (canUseDataForSeo) {
      apiPromises.push(
        searchDataForSeo(requestedStoreId ? siteSpecificQuery : effectiveApiQuery, {
          location,
          hl,
          login: dataForSeoLogin,
          password: dataForSeoPassword,
        }).then(res => dataForSeoResults = res).catch(() => {})
      );
    }

    if (serpApiKey) {
      apiPromises.push(
        searchSerpApi(requestedStoreId ? siteSpecificQuery : effectiveApiQuery, serpApiKey, { location, hl })
          .then(res => serpApiResults = res).catch(() => {})
      );
    }

    if (serperApiKey) {
      apiPromises.push(
        searchSerper(requestedStoreId ? siteSpecificQuery : effectiveApiQuery, serperApiKey, { location, hl })
          .then(res => serperResults = res).catch(() => {})
      );
    }

    // Wait for all APIs and Scrapers (with timeout)
    await Promise.allSettled([...apiPromises, scraperPromise.then(res => scrapedResults = res)]);

    // FALLBACK: If a specific store is requested and we got ZERO results, try a general web search with 'site:'
    if (requestedStoreId && (dataForSeoResults.length + serpApiResults.length + serperResults.length + scrapedResults.length === 0)) {
      const requestedStore = PRIORITY_STORES.find(s => s.id === requestedStoreId.toLowerCase());
      if (requestedStore && requestedStore.hosts && serperApiKey) {
        for (const host of requestedStore.hosts) {
          try {
            const fallbackResults = await searchSerperGeneral(query, serperApiKey, { 
              site: host,
              location 
            });
            if (fallbackResults.length > 0) {
              serperResults = fallbackResults;
              break; // Stop if we found results for this host
            }
          } catch (e) {
            console.warn(`Fallback search for ${host} failed`, e);
          }
        }
      }
    }

    const mergedResults = mergeHybridSearchResults([
      ...dataForSeoResults,
      ...serpApiResults,
      ...serperResults,
      ...scrapedResults,
    ]);
    const filteredResults = SAUDI_FAMOUS_STORES_ONLY
      ? filterToPriorityStores(mergedResults)
      : mergedResults;
    const storeScopedResults = requestedStoreId
      ? filterResultsByStoreId(filteredResults, requestedStoreId)
      : filteredResults;
    const finalResults = storeScopedResults.slice(0, MAX_TOTAL_RESULTS);

    return jsonResponse(
      {
        query,
        requestedStoreId,
        vertical: searchVertical,
        debug: {
          effectiveApiQuery,
          siteSpecificQuery,
          targetedStores: targetedStores.map(s => s.id),
          storesToScrape: storesToScrape.map(s => s.id),
          canUseDataForSeo,
          hasSerpApiKey: !!serpApiKey,
          hasSerperApiKey: !!serperApiKey,
          mergedCount: mergedResults.length,
          firstMergedResult: mergedResults.length > 0 ? {
            title: mergedResults[0].title,
            storeId: mergedResults[0].storeId,
            productUrl: mergedResults[0].productUrl
          } : null
        },
        counts: {
          total: finalResults.length,
          dataforseo: dataForSeoResults.length,
          serpApi: serpApiResults.length,
          serper: serperResults.length,
          scraper: scrapedResults.length,
        },
        notice: buildHybridSearchNotice({
          dataForSeoResults,
          serpApiResults,
          serperResults,
          scrapedResults,
        }),
        results: finalResults,
      },
      200,
      request,
    );
  },
};

function buildCorsHeaders(request) {
  const origin = request.headers.get('origin');
  return {
    'Access-Control-Allow-Origin': origin || '*',
    Vary: 'Origin',
    'Access-Control-Allow-Methods': ALLOWED_CORS_METHODS,
    'Access-Control-Allow-Headers': ALLOWED_CORS_HEADERS,
    'Access-Control-Max-Age': '3600',
    'content-type': 'application/json; charset=utf-8',
  };
}

function jsonResponse(payload, status, request) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: buildCorsHeaders(request),
  });
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
    const rows = Array.isArray(group?.shopping_results) ? group.shopping_results : [];
    for (const item of rows) {
      const result = normalizeSerpApiResult(item);
      if (result) {
        candidates.push(result);
      }
    }
  }

  return candidates;
}

async function searchSerperGeneral(query, apiKey, { site, location = 'Saudi Arabia' } = {}) {
  const url = 'https://google.serper.dev/search';
  const payload = {
    q: `site:${site} ${query}`,
    location: location,
    gl: 'sa',
    hl: 'ar',
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'X-API-KEY': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  if (!data || !Array.isArray(data.organic)) {
    return [];
  }

  const candidates = [];
  for (const item of data.organic) {
    const result = normalizeSerperGeneralResult(item, site);
    if (result) {
      candidates.push(result);
    }
  }

  return candidates;
}

function normalizeSerperGeneralResult(item, site) {
  if (!item || !item.title || !item.link) {
    return null;
  }

  // General search snippets sometimes contain price info
  const snippet = item.snippet || '';
  const priceInfo = parsePriceValue(snippet);
  
  // If no price found in snippet, we can't show it as a product result
  if (priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const store = resolveStoreInfo({ storeName: '', productUrl: item.link });

  return {
    title: cleanProductTitle(item.title),
    priceValue: priceInfo.value,
    price: formatPriceLabel(priceInfo.value, priceInfo.currency),
    currency: priceInfo.currency,
    storeName: store.name,
    storeId: store.id,
    storeLogoUrl: buildStoreLogoUrl(site),
    imageUrl: '',
    productUrl: item.link,
    sourceType: 'serper_general',
    channelType: store.channelType,
    isLiveDirect: false,
  };
}

async function searchSerper(query, apiKey, { location = 'Saudi Arabia', hl = 'ar' } = {}) {
  const url = 'https://google.serper.dev/shopping';
  const payload = {
    q: query,
    location: location,
    gl: 'sa',
    hl: hl,
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'X-API-KEY': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    return [];
  }

  const data = await response.json();
  if (!data || !Array.isArray(data.shopping)) {
    return [];
  }

  const candidates = [];
  for (const item of data.shopping) {
    const result = normalizeSerperResult(item);
    if (result) {
      candidates.push(result);
    }
  }

  return candidates;
}

function normalizeSerperResult(item) {
  if (!item || typeof item !== 'object') {
    return null;
  }

  const title = item.title;
  const productUrl = item.link;
  const imageUrl = item.imageUrl;
  const priceInfo = parsePriceValue(item.price);

  if (!title || !productUrl || priceInfo.value == null || priceInfo.value <= 0) {
    return null;
  }

  const storeName = item.source;
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
    sourceType: 'serper',
    channelType: store.channelType,
    isLiveDirect: false,
  };
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

  const title = firstNonEmpty([item.title, item.product_title, item.name]);
  const productUrl = firstNonEmpty([item.product_link, item.link, item.url]);
  const imageUrl = firstNonEmpty([
    item.thumbnail,
    item.image,
    Array.isArray(item.thumbnails) ? item.thumbnails[0] : '',
  ]);

  const priceInfo = parsePriceValue(
    firstNonEmpty([item.price, item.extracted_price, item.price_value, item.raw_price]),
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

  const title = firstNonEmpty([item.title, item.product_title, item.name]);
  const productUrl = firstNonEmpty([item.url, item.link, item.product_url, item.shop_ad_aclk]);
  const imageUrl = firstNonEmpty([item.image_url, item.thumbnail, item.image]);

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

  const storeName = firstNonEmpty([item.seller, item.merchant, item.source, item.shop]);
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

    console.warn('A priority store scraper failed.', {
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
      console.warn('Store scraping request failed.', {
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
  const scriptSelectors = ['#__NEXT_DATA__', '#__NUXT_DATA__', 'script[data-rh="true"]'];

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
    firstNonEmpty([card.attr('href'), card.find('a[href]').first().attr('href')]),
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
    firstNonEmpty([node.url, node.link, node.productUrl, node.slug, node['@id']]),
    searchUrl,
  );
  if (!productUrl) {
    return null;
  }

  const imageUrl = normalizeImageUrl(
    absoluteUrl(extractImageValue(node.image || node.imageUrl || node.thumbnail), searchUrl),
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

function buildHybridSearchNotice({ dataForSeoResults, serpApiResults, serperResults, scrapedResults }) {
  if (scrapedResults.length > 0 && (dataForSeoResults.length > 0 || serpApiResults.length > 0 || serperResults.length > 0)) {
    return 'تم دمج نتائج البحث العالمية مع الزحف المباشر من مواقع المتاجر المحلية.';
  }
  if (dataForSeoResults.length > 0) {
    return 'تم عرض نتائج DataForSEO حسب المدينة المحددة.';
  }
  if (serperResults.length > 0) {
    return 'تم عرض نتائج Serper.dev بدقة عالية.';
  }
  if (serpApiResults.length > 0) {
    return 'تم عرض نتائج SerpApi للمقارنة.';
  }
  if (scrapedResults.length > 0) {
    return 'تم عرض نتائج مباشرة من مواقع المتاجر الرسمية.';
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

function filterResultsByStoreId(results, requestedStoreId) {
  const normalizedRequestedStoreId = String(requestedStoreId || '')
    .trim()
    .toLowerCase();
  if (!normalizedRequestedStoreId) {
    return results;
  }

  return results.filter((item) => {
    const directStoreId = String(item?.storeId || '').trim().toLowerCase();
    if (directStoreId === normalizedRequestedStoreId) {
      return true;
    }

    const resolvedStore = resolveStoreInfo({
      storeName: item?.storeName || '',
      productUrl: item?.productUrl || '',
    });
    return (
      String(resolvedStore?.id || '').trim().toLowerCase() === normalizedRequestedStoreId
    );
  });
}

function inferSearchVertical(query) {
  const normalized = normalizeArabic(query);
  const pharmacyHints = ['دواء', 'صيدلية', 'حبوب', 'مسكن', 'بنادول', 'فيتامين', 'مرطب', 'كريم'];
  const groceryHints = [
    'حليب',
    'خبز',
    'رز',
    'ارز',
    'شعير',
    'مصري',
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
  const beautyHints = ['عطر', 'عطور', 'برفان', 'مكياج', 'كريم', 'شامبو', 'عنايه'];
  const cafeHints = ['قهوه', 'قهوة', 'كافي', 'كافيه', 'اسبريسو', 'لاتيه', 'كابتشينو', 'كوفي'];

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

function selectStoresForSearch(vertical, requestedStoreId) {
  const normalizedRequestedStoreId = String(requestedStoreId || '')
    .trim()
    .toLowerCase();
  if (!normalizedRequestedStoreId) {
    return selectStoresForVertical(vertical);
  }

  const requestedStore = PRIORITY_STORES.find(
    (store) => store.id === normalizedRequestedStoreId,
  );
  if (requestedStore) {
    return [requestedStore];
  }

  return selectStoresForVertical(vertical);
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
    ((node.name || node.title) &&
      (node.price || node.lowPrice || node.offers || node.priceSpecification));

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

  // If query is short (1-2 words), require at least one token
  if (tokens.length <= 2) {
    return tokens.some((token) => normalizedTitle.includes(token));
  }

  // For longer queries, require at least 50% of tokens to match to increase accuracy
  const matchCount = tokens.filter((token) => normalizedTitle.includes(token)).length;
  return matchCount >= Math.ceil(tokens.length / 2);
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

  const text = normalizeDigits(String(value))
    .replace(/&nbsp;/gi, ' ')
    .replace(/[,،]/g, '')
    .trim();

  if (!text || text.length > 500) {
    return { value: null, currency: 'SAR' };
  }

  // Find all candidate numbers
  const matches = text.match(/([0-9]+(?:\.[0-9]{1,2})?)/g);
  if (!matches || matches.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  const candidates = matches.map(m => Number.parseFloat(m))
    .filter(val => val > 0 && !isNaN(val));

  if (candidates.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  // Filter out numbers that look like years (1990-2030) if we have other options
  let finalValue = candidates[0];
  if (candidates.length > 1) {
    const nonYear = candidates.filter(val => val < 1900 || val > 2050);
    if (nonYear.length > 0) {
      finalValue = nonYear[0];
    }
  }

  const currency = /(SAR|ريال|ر\.?\s?س)/i.test(text) ? 'SAR' : 'SAR';
  return {
    value: Number.isFinite(finalValue) ? finalValue : null,
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

async function fetchJsonWithBasicAuth(url, { login, password, body }) {
  const credentials = btoa(`${login}:${password}`);
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
  return String(value || '')
    .trim()
    .replace(/;$/, '');
}
