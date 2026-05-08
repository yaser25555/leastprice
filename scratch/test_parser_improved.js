
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

  // Handle Arabic separators before removing commas
  let text = normalizeDigits(String(value))
    .replace(/&nbsp;/gi, ' ')
    .replace(/٫/g, '.')  // Arabic decimal separator
    .replace(/٬/g, '')   // Arabic thousands separator
    .replace(/,/g, '')   // English thousands separator
    .replace(/،/g, '')   // Arabic comma
    .trim();

  if (!text || text.length > 1000) {
    return { value: null, currency: 'SAR' };
  }

  // 1. Try to find a number immediately followed or preceded by a currency symbol
  // We improve the regex to be more inclusive and handle cases where it might be at the end of a string
  const currencySymbols = 'SAR|ريال|ر\.?\s?س|SR|S\.R|ريالاً|ريالات';
  const priceRegex = `([0-9]+(?:\\.[0-9]{1,3})?)`;
  const currencyMatch = text.match(new RegExp(`(?:(?:${currencySymbols})\\s*${priceRegex})|(?:${priceRegex}\\s*(?:${currencySymbols}))`, 'i'));
  
  if (currencyMatch) {
    const val = Number.parseFloat(currencyMatch[1] || currencyMatch[2]);
    if (val > 0) return { value: val, currency: 'SAR' };
  }

  // 2. Find all candidate numbers
  const matches = [...text.matchAll(/([0-9]+(?:\.[0-9]{1,3})?)/g)];
  if (matches.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  const forbiddenUnits = [
    'k', 'inch', 'بوصة', 'جم', 'مل', 'جرام', 'كجم', 'وات', 'w', 'v', 'فولت', 
    'هرتز', 'hz', 'fps', 'gb', 'mb', 'tb', 'جيجا', 'ميج', 'بكسل', 'pixel',
    'l', 'لتر', 'pcs', 'حبة', 'قطعة', 'sachet', 'كيس', 'عبوة', 'mg', 'ملجم', 'مجم',
    'gm', 'g', 'kg', 'lb', 'oz'
  ];
  
  const candidates = [];

  for (const match of matches) {
    const val = Number.parseFloat(match[1]);
    if (isNaN(val) || val <= 0) continue;

    const index = match.index;
    const afterText = text.slice(index + match[0].length, index + match[0].length + 20).toLowerCase();
    const beforeText = text.slice(Math.max(0, index - 15), index).toLowerCase();
    
    // Check if this number is followed by a unit
    const isForbidden = forbiddenUnits.some(unit => {
      const unitRegex = new RegExp(`^\\s*${unit}\\b|^\\s*${unit}\\s`, 'i');
      return unitRegex.test(afterText);
    });

    if (!isForbidden) {
      candidates.push({
          value: val,
          isLikelyPrice: (new RegExp(currencySymbols, 'i').test(afterText) || new RegExp(currencySymbols, 'i').test(beforeText)),
          index: index
      });
    }
  }

  if (candidates.length === 0) {
    return { value: null, currency: 'SAR' };
  }

  // Priority 1: If any candidate was near a currency symbol (even if currencyMatch failed due to complex spacing)
  const priceCandidates = candidates.filter(c => c.isLikelyPrice);
  if (priceCandidates.length > 0) {
      return { value: priceCandidates[0].value, currency: 'SAR' };
  }

  // Priority 2: Filter out very small numbers that look like quantities or versions if there are larger numbers
  const badCandidates = new Set([24, 32, 40, 43, 50, 55, 65, 75, 85, 2023, 2024, 2025, 2026]); // Removed 100, 500, 1000
  const filtered = candidates.filter(c => !badCandidates.has(c.value));
  
  // Pick the LAST one from filtered or candidates, as prices are usually at the end
  const finalCandidates = filtered.length > 0 ? filtered : candidates;
  let finalValue = finalCandidates[finalCandidates.length - 1].value;

  // Electronics heuristic: if we have a very large number and some small numbers, pick the large one
  if (candidates.length > 1) {
    const values = candidates.map(c => c.value);
    const maxVal = Math.max(...values);
    const minVal = Math.min(...values);
    if (maxVal > 100 && minVal < 10) {
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
    "Milk 1L - 5.50",
    "Buy 3 pieces for 15.00 SAR",
    "45.50"
];

testCases.forEach(tc => {
    const res = parsePriceValue(tc);
    console.log(`Input: "${tc}" -> Result: ${res.value} ${res.currency}`);
});
