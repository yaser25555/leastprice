const https = require('https');

const queries = [
  { q: 'زيت', store: 'panda' },
  { q: 'زيتون', store: 'othaim' }
];
const workerUrl = 'https://leastprice-hybrid-search.leastprice-yaser.workers.dev';

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function runTests() {
  console.log('--- Specific Store Test ---');
  for (const test of queries) {
    const url = `${workerUrl}?q=${encodeURIComponent(test.q)}&store=${test.store}`;
    console.log(`\nTesting: "${test.q}" in ${test.store}`);
    console.log(`URL: ${url}`);
    try {
      const result = await fetchJson(url);
      const data = result.data;
      
      console.log(`Status: ${result.status}`);
      console.log(`Counts: ${JSON.stringify(data.counts)}`);
      console.log(`Total Results: ${data.results?.length || 0}`);
      
      if (data.results && data.results.length > 0) {
        console.log(`Top result: ${data.results[0].title} - ${data.results[0].price} at ${data.results[0].storeName}`);
      } else {
        console.log('No results found.');
      }
    } catch (err) {
      console.error(`Error: ${err.message}`);
    }
  }
}

runTests();
