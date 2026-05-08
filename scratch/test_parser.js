
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

  // 1. Try to find a number immediately followed or preceded by a currency symbol
  const currencyMatch = text.match(/((?:SAR|ريال|ر\.?\s?س)\s*([0-9]+(?:\.[0-9]{1,2})?))|(([0-9]+(?:\.[0-9]{1,2})?)\s*(?:SAR|ريال|ر\.?\s?س))/i);
  if (currencyMatch) {
    const val = Number.parseFloat(currencyMatch[2] || currencyMatch[4]);
    if (val > 0) return { value: val, currency: 'SAR' };
  }

  // 2. If no currency match, find all candidate numbers and check their context
  const matches = [...text.matchAll(/([0-9]+(?:\.[0-9]{1,2})?)/g)];
  if (matches.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  const forbiddenUnits = [
    'k', 'inch', 'بوصة', 'جم', 'مل', 'جرام', 'كجم', 'وات', 'w', 'v', 'فولت', 
    'هرتز', 'hz', 'fps', 'gb', 'mb', 'tb', 'جيجا', 'ميج', 'بكسل', 'pixel'
  ];
  const candidates = [];

  for (const match of matches) {
    const val = Number.parseFloat(match[1]);
    if (isNaN(val) || val <= 0) continue;

    // Check the text immediately following this number
    const index = match.index;
    const afterText = text.slice(index + match[0].length, index + match[0].length + 15).toLowerCase();
    
    const isForbidden = forbiddenUnits.some(unit => {
      // Ensure the unit is not part of another word, e.g. "SAR"
      const unitRegex = new RegExp(`^\\s*${unit}\\b|^\\s*${unit}\\s`, 'i');
      return unitRegex.test(afterText);
    });

    if (!isForbidden) {
      candidates.push(val);
    }
  }

  if (candidates.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  // Filter out common sizes/years/quantities if possible
  const badCandidates = new Set([24, 32, 40, 43, 50, 55, 65, 75, 85, 100, 500, 1000, 2023, 2024, 2025, 2026]);
  
  const betterCandidates = candidates.filter(val => !badCandidates.has(val));
  let finalValue = betterCandidates.length > 0 ? betterCandidates[0] : candidates[0];

  // If we have a very small number and a large number, the large one is more likely the price for electronics
  if (candidates.length > 1) {
    const maxVal = Math.max(...candidates);
    const minVal = Math.min(...candidates);
    if (maxVal > 500 && minVal < 100) {
      finalValue = maxVal;
    }
  }

  return {
    value: Number.isFinite(finalValue) ? finalValue : null,
    currency: 'SAR',
  };
}

const testCases = [
    "١٬٢٩٩ ر.س",
    "Price: 1,500.00 SAR",
    "Nescafe 3 in 1 - 30 sachets - 45.00",
    "1,000 SAR",
    "500 SAR",
    "Qty: 1 Price: 100",
    "Smart TV 55 inch - 1500 SAR",
    "Iphone 15 Pro - 128GB - 4500",
    "Milk 1L - 5.50"
];

testCases.forEach(tc => {
    const res = parsePriceValue(tc);
    console.log(`Input: "${tc}" -> Result: ${res.value} ${res.currency}`);
});
