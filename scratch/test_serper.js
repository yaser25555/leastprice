const fetch = require('node-fetch');

async function testSerper(query, site, apiKey) {
  const url = 'https://google.serper.dev/shopping';
  const payload = {
    q: `site:${site} ${query}`,
    location: 'Saudi Arabia',
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

  const data = await response.json();
  console.log(JSON.stringify(data, null, 2));
}

// Note: I will need the API key to run this, but I can't see it.
// I will instead ask the user to verify or I will use a mock/assumption.
// Wait, I can't run this without a key.
