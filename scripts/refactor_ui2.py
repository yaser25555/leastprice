import re
import os
import subprocess

def extract_balanced_braces(text, start_index):
    count = 0
    in_string = False
    string_char = ''
    i = start_index
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
                    return text[start_index:i+1]
        i += 1
    return text[start_index:]

def remove_method(text, method_name):
    pattern = r'(Future<void>|void)\s+' + method_name + r'\s*\([^)]*\)\s*(async\s*)?\{'
    match = re.search(pattern, text)
    if not match:
        return text
    start_idx = match.end() - 1
    method_body = extract_balanced_braces(text, start_idx)
    full_method = match.group()[:-1] + method_body
    return text.replace(full_method, '')

def main():
    file_path = r'd:\leastprice\lib\features\home\least_price_home_page.dart'
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print("File not found")
        return

    # 1. ConsumerStatefulWidget
    content = content.replace('class LeastPriceHomePage extends StatefulWidget', 'class LeastPriceHomePage extends ConsumerStatefulWidget')
    content = content.replace('State<LeastPriceHomePage> createState() =>', 'ConsumerState<LeastPriceHomePage> createState() =>')
    content = content.replace('class _LeastPriceHomePageState extends State<LeastPriceHomePage>', 'class _LeastPriceHomePageState extends ConsumerState<LeastPriceHomePage>')

    # 2. Imports
    if "import 'package:leastprice/features/home/home_search_provider.dart';" not in content:
        content = content.replace("import 'home_exports.dart';", "import 'home_exports.dart';\nimport 'package:leastprice/features/home/home_search_provider.dart';")

    # 3. Remove local state fields
    content = re.sub(r'String\s+_query\s*=\s*.*?;', '', content)
    content = re.sub(r'String\?\s+_selectedSearchCategory;', '', content)
    content = re.sub(r'String\s+_selectedSearchStore\s*=\s*.*?;', '', content)
    content = re.sub(r'MarketplaceSearchCity\s+_selectedSearchCity\s*=\s*.*?;', '', content)
    content = re.sub(r'bool\s+_isSearchingOnline\s*=\s*.*?;', '', content)
    content = re.sub(r'bool\s+_isLoadingMore\s*=\s*.*?;', '', content)
    content = re.sub(r'int\s+_currentSearchOffset\s*=\s*.*?;', '', content)
    content = re.sub(r'bool\s+_hasMoreSearchResults\s*=\s*.*?;', '', content)
    content = re.sub(r'String\?\s+_smartSearchNotice;', '', content)
    content = re.sub(r'String\s+_comparisonSearchSourceLabel\s*=\s*.*?;', '', content)
    content = re.sub(r'List<ComparisonSearchResult>\s+_comparisonSearchResults\s*=\s*.*?;', '', content)

    # 4. Remove methods safely
    methods_to_remove = [
        '_performSerpSearch',
        '_loadMoreSearchResults',
        '_runSmartSearch',
        '_scheduleSmartSearch',
        '_clearSearch',
        '_submitComparisonSearch',
        '_clearSmartSearchState',
        '_selectSearchCity'
    ]
    for method in methods_to_remove:
        content = remove_method(content, method)

    # 5. Inject state into build
    build_pattern = r'(Widget\s+build\(BuildContext\s+context\)\s*\{)'
    build_injection = r'\1\n    final searchState = ref.watch(homeSearchProvider);\n    final searchNotifier = ref.read(homeSearchProvider.notifier);\n'
    content = re.sub(build_pattern, build_injection, content, count=1)

    # 6. Variable replacements
    content = re.sub(r'\b_query\b', 'searchState.query', content)
    content = re.sub(r'\b_selectedSearchCategory\b', 'searchState.selectedCategory', content)
    content = re.sub(r'\b_selectedSearchStore\b', 'searchState.selectedStore', content)
    content = re.sub(r'\b_selectedSearchCity\b', 'searchState.selectedCity', content)
    content = re.sub(r'\b_isSearchingOnline\b', 'searchState.isSearchingOnline', content)
    content = re.sub(r'\b_isLoadingMore\b', 'searchState.isLoadingMore', content)
    content = re.sub(r'\b_currentSearchOffset\b', 'searchState.currentOffset', content)
    content = re.sub(r'\b_hasMoreSearchResults\b', 'searchState.hasMoreResults', content)
    content = re.sub(r'\b_smartSearchNotice\b', 'searchState.searchNotice', content)
    content = re.sub(r'\b_comparisonSearchSourceLabel\b', 'searchState.searchSourceLabel', content)
    content = re.sub(r'\b_comparisonSearchResults\b', 'searchState.results', content)

    # 7. Update UI callbacks
    content = re.sub(r'onClearSearch:\s*searchNotifier.clearSearch\(\)', 'onClearSearch: searchNotifier.clearSearch', content)
    content = re.sub(r'onSubmitted:\s*\(value\)\s*\{\s*unawaited\(searchNotifier.performSearch\(forceRefresh:\s*true\)\);\s*\}', r'onSubmitted: (value) { searchNotifier.setQuery(value); searchNotifier.performSearch(forceRefresh: true); }', content)
    
    # Clean up empty setStates
    content = re.sub(r'setState\(\(\)\s*\{\s*\}\);', '', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Done")

if __name__ == '__main__':
    main()
