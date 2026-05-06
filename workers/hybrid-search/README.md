# LeastPrice Hybrid Search Worker

Cloudflare Worker replacement for `hybridMarketplaceSearch`.

## Setup

```bash
npm install
npx wrangler secret put DATAFORSEO_LOGIN
npx wrangler secret put DATAFORSEO_PASSWORD
```

`SERPAPI_KEY` is optional. The Worker can run with DataForSEO only, then gain broader fallback coverage once SerpApi is added.

## Local dev

```bash
npm run dev
```

The Worker accepts:

- `q`
- `location`
- `hl`
- `store`

It responds with the same JSON shape expected by the Flutter client.

## Deploy

```bash
npm run deploy
```

After deploy, set Flutter's search endpoint to the Worker URL:

```bash
flutter build web --dart-define=HYBRID_SEARCH_BASE_URL=https://leastprice-hybrid-search.leastprice-yaser.workers.dev
```

Or for mobile:

```bash
flutter run --dart-define=HYBRID_SEARCH_BASE_URL=https://leastprice-hybrid-search.leastprice-yaser.workers.dev
```
