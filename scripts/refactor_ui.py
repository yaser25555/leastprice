import re
import sys

def main():
    file_path = r'd:\leastprice\lib\features\home\least_price_home_page.dart'
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print("File not found")
        return

    # 1. Change to ConsumerStatefulWidget
    content = content.replace('class LeastPriceHomePage extends StatefulWidget {', 'class LeastPriceHomePage extends ConsumerStatefulWidget {')
    content = content.replace('State<LeastPriceHomePage> createState() => _LeastPriceHomePageState();', 'ConsumerState<LeastPriceHomePage> createState() => _LeastPriceHomePageState();')
    content = content.replace('class _LeastPriceHomePageState extends State<LeastPriceHomePage> {', 'class _LeastPriceHomePageState extends ConsumerState<LeastPriceHomePage> {')

    # 2. Add imports
    if "import 'package:leastprice/features/home/home_search_provider.dart';" not in content:
        content = content.replace("import 'home_exports.dart';", "import 'home_exports.dart';\nimport 'package:leastprice/features/home/home_search_provider.dart';")

    # 3. Remove local state variables
    vars_to_remove = [
        r"Timer\?\s+_smartSearchDebounce;\n",
        r"String\s+_query\s*=\s*'';\n",
        r"String\?\s+_selectedSearchCategory;\n",
        r"String\s+_selectedSearchStore\s*=\s*'الكل';\n",
        r"MarketplaceSearchCity\s+_selectedSearchCity\s*=\s*marketplaceSearchCities.first;\n",
        r"bool\s+_hasInternet\s*=\s*true;\n",
        r"bool\s+_isSearchingOnline\s*=\s*false;\n",
        r"bool\s+_isLoadingMore\s*=\s*false;\n",
        r"int\s+_currentSearchOffset\s*=\s*0;\n",
        r"bool\s+_hasMoreSearchResults\s*=\s*true;\n",
        r"String\?\s+_smartSearchNotice;\n",
        r"String\s+_comparisonSearchSourceLabel\s*=\s*tr\('بحث السوق',\s*'Market search'\);\n",
        r"List<ComparisonSearchResult>\s+_comparisonSearchResults\s*=\s*const\s*<ComparisonSearchResult>\[\];\n",
    ]
    for pattern in vars_to_remove:
        content = re.sub(pattern, '', content)

    # 4. Inject ref.watch into build
    build_pattern = r'(Widget\s+build\(BuildContext\s+context\)\s*\{)'
    build_injection = r'\1\n    final searchState = ref.watch(homeSearchProvider);\n    final searchNotifier = ref.read(homeSearchProvider.notifier);\n'
    content = re.sub(build_pattern, build_injection, content)

    # 5. Variable replacements in UI
    replacements = {
        r'\b_query\b': 'searchState.query',
        r'\b_selectedSearchCategory\b': 'searchState.selectedCategory',
        r'\b_selectedSearchStore\b': 'searchState.selectedStore',
        r'\b_selectedSearchCity\b': 'searchState.selectedCity',
        r'\b_hasInternet\b': 'searchState.hasInternet',
        r'\b_isSearchingOnline\b': 'searchState.isSearchingOnline',
        r'\b_isLoadingMore\b': 'searchState.isLoadingMore',
        r'\b_currentSearchOffset\b': 'searchState.currentOffset',
        r'\b_hasMoreSearchResults\b': 'searchState.hasMoreResults',
        r'\b_smartSearchNotice\b': 'searchState.searchNotice',
        r'\b_comparisonSearchSourceLabel\b': 'searchState.searchSourceLabel',
        r'\b_comparisonSearchResults\b': 'searchState.results',
    }
    
    # We only want to replace these variables in the build method and UI components,
    # but since we are removing the methods, global replace is mostly fine.
    for old, new in replacements.items():
        content = re.sub(old, new, content)

    # 6. Replace method calls
    content = re.sub(r'_clearSearch\(\)', 'searchNotifier.clearSearch()', content)
    content = re.sub(r'_loadMoreSearchResults', '() => searchNotifier.performSearch(isLoadMore: true)', content)
    content = re.sub(r'_selectSearchCity\((.*?)\)', r'searchNotifier.setCity(marketplaceSearchCityById(\1)); searchNotifier.performSearch(forceRefresh: true)', content)
    
    # Handle text changes
    content = re.sub(r'onChanged:\s*\(val\)\s*\{\s*_scheduleSmartSearch\(val\);\s*\}', r'onChanged: (val) { searchNotifier.setQuery(val); searchNotifier.performSearch(); }', content)
    content = re.sub(r'onSubmitted:\s*\(val\)\s*\{\s*_submitComparisonSearch\(val\);\s*\}', r'onSubmitted: (val) { searchNotifier.setQuery(val); searchNotifier.performSearch(forceRefresh: true); }', content)
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Refactoring script executed successfully.")

if __name__ == '__main__':
    main()
