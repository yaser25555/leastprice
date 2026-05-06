const https = require('https');

const queries = [
  { q: 'سكر', store: '' },
  { q: 'خبز', store: 'panda' },
  { q: 'قهوة', store: 'othaim' },
  { q: 'تلفزيون سامسونج', store: 'extra' }
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
  console.log('--- Final Search Verification ---');
  for (const test of queries) {
    const url = `${workerUrl}?q=${encodeURIComponent(test.q)}${test.store ? '&store=' + test.store : ''}`;
    console.log(`\nTesting: "${test.q}" ${test.store ? 'in ' + test.store : '(General)'}`);
    try {
      const result = await fetchJson(url);
      const data = result.data;
      
      console.log(`Status: ${result.status}`);
      console.log(`Notice: ${data.notice}`);
      console.log(`Total Results: ${data.counts?.total || 0}`);
      
      if (data.results && data.results.length > 0) {
        data.results.slice(0, 3).forEach((r, i) => {
          console.log(` [${i+1}] ${r.title} - ${r.price} at ${r.storeName}`);
        });
      } else {
        console.log('No results found.');
      }
    } catch (err) {
      console.error(`Error: ${err.message}`);
    }
  }
}

runTests();
