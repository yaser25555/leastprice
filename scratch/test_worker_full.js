const https = require('https');

const queries = ['iphone 16', 'حليب المراعي', 'بنادول', 'ثلاجة ال جي'];
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
  console.log('--- LeastPrice Search Worker Test Report ---');
  for (const q of queries) {
    console.log(`\nTesting Query: "${q}"`);
    try {
      const result = await fetchJson(`${workerUrl}?q=${encodeURIComponent(q)}`);
      const data = result.data;
      
      console.log(`Status: ${result.status}`);
      console.log(`Notice: ${data.notice}`);
      console.log(`Total Results: ${data.counts?.total || 0}`);
      
      if (data.results && data.results.length > 0) {
        const stores = [...new Set(data.results.map(r => r.storeName))];
        console.log(`Stores Found: ${stores.join(', ')}`);
        console.log(`Price Range: ${data.results[0].price} - ${data.results[data.results.length-1].price}`);
      } else {
        console.log('No results found.');
      }
    } catch (err) {
      console.error(`Error testing "${q}": ${err.message}`);
    }
  }
}

runTests();
