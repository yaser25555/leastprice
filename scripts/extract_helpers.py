import re

def extract_method(text, method_name, is_class_or_enum=False):
    if is_class_or_enum:
        pattern = r'(enum|class)\s+' + method_name + r'\b[^\{]*\{'
    else:
        pattern = r'(?:[a-zA-Z<>\[\]\?_]+\s+)' + method_name + r'\s*\([^)]*\)\s*\{'
        
    match = re.search(pattern, text)
    if not match:
        return text, None
        
    start_idx = match.start()
    brace_idx = match.end() - 1
    
    count = 0
    in_string = False
    string_char = ''
    i = brace_idx
    
    while i < len(text):
        char = text[i]
        if char in ("'", '"') and (i == 0 or text[i-1] != '\\'):
            if not in_string:
                in_string = True
                string_char = char
            elif string_char == char:
                in_string = False
        if not in_string:
            if char == '{':
                count += 1
            elif char == '}':
                count -= 1
                if count == 0:
                    method_content = text[start_idx:i+1]
                    new_text = text[:start_idx] + text[i+1:]
                    return new_text, method_content
        i += 1
    return text, None

def main():
    file_path = r'd:\leastprice\lib\core\utils\helpers.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    url_methods = [
        'hostFromUrl',
        'storeIdForHost',
        'domainForStoreId',
        'inferStoreIdFromUrl',
        'inferComparisonChannelType',
        'resolveStoreLogoUrl',
        'normalizeStoreIdToken'
    ]
    
    formatter_methods = [
        'formatPrice',
        'formatAmountValue',
        'extractMarketplacePrice',
        'normalizeArabic'
    ]
    
    validator_methods = [
        'isAllowedAdminEmail',
        'isAdminPathToken',
        'isAdminDashboardRequest',
    ]
    
    url_content = "import 'package:leastprice/core/utils/helpers.dart';\n\n"
    formatter_content = "import 'package:leastprice/core/utils/helpers.dart';\n\n"
    validator_content = "import 'package:leastprice/core/config/least_price_data_config.dart';\nimport 'package:leastprice/core/utils/helpers.dart';\n\n"
    
    for m in url_methods:
        content, m_content = extract_method(content, m)
        if m_content: url_content += m_content + "\n\n"
        
    for m in formatter_methods:
        content, m_content = extract_method(content, m)
        if m_content: formatter_content += m_content + "\n\n"
        
    for m in validator_methods:
        content, m_content = extract_method(content, m)
        if m_content: validator_content += m_content + "\n\n"

    # Add the manually created functions back
    validator_content += """
String? normalizeEmailAddress(String rawEmail) {
  final value = rawEmail.trim().toLowerCase();
  if (value.isEmpty) {
    return null;
  }

  const pattern = r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$';
  return RegExp(pattern, caseSensitive: false).hasMatch(value) ? value : null;
}
"""

    url_content += """
String normalizedImageUrl(
  String? rawUrl, {
  String fallbackLabel = 'LeastPrice',
}) {
  final value = (rawUrl ?? '').trim();

  final isLocalhost = value.contains('localhost') ||
      value.contains('127.0.0.1') ||
      value.contains('0.0.0.0');
  final isValidScheme =
      value.startsWith('http://') || value.startsWith('https://');

  if (value.isEmpty || isLocalhost || !isValidScheme) {
    final encoded = Uri.encodeComponent(
        fallbackLabel.isNotEmpty ? fallbackLabel : 'LeastPrice');
    return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
  }

  const brokenTokens = <String>[
    'photo-1570194065650-d99fb4d8a5c8',
    'photo-1556228578-dd6c36f7737d',
    'photo-1588405748880-12d1d2a59df9',
  ];

  for (final token in brokenTokens) {
    if (value.contains(token)) {
      final encoded = Uri.encodeComponent(fallbackLabel);
      return 'https://placehold.co/900x600/EAF3EF/17332B?text=$encoded';
    }
  }

  return value;
}
"""

    formatter_content += """
String formatPercentage(double value) {
  return '${formatAmountValue(value)}%';
}

String? formatSaudiPhoneNumber(String rawNumber) {
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+9665') && digits.length == 13) {
    return digits;
  }
  if (digits.startsWith('9665') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('05') && digits.length == 10) {
    return '+966${digits.substring(1)}';
  }
  if (digits.startsWith('5') && digits.length == 9) {
    return '+966$digits';
  }
  return null;
}
"""

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    with open(r'd:\leastprice\lib\core\utils\formatters.dart', 'w', encoding='utf-8') as f:
        f.write(formatter_content)
        
    with open(r'd:\leastprice\lib\core\utils\url_utils.dart', 'w', encoding='utf-8') as f:
        f.write(url_content)
        
    with open(r'd:\leastprice\lib\core\utils\validators.dart', 'w', encoding='utf-8') as f:
        f.write(validator_content)

    print("Extraction complete")

if __name__ == '__main__':
    main()
