import re

def remove_balanced_block(text, start_pattern):
    match = re.search(start_pattern, text)
    if not match:
        return text
    start_idx = match.start()
    
    # Find the end of the block by counting braces
    count = 0
    in_string = False
    string_char = ''
    i = match.end() - 1 # starts at '{' or something
    
    # We actually need to find the matching brace for the sliver element, but in Dart UI code, it might be a method call like SliverToBoxAdapter(...)
    # Let's use a simpler approach: regex for the blocks since they are well known.
    pass

def main():
    file_path = r'd:\leastprice\lib\features\home\least_price_home_page.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. State changes
    content = content.replace('class LeastPriceHomePage extends StatefulWidget', 'class LeastPriceHomePage extends ConsumerStatefulWidget')
    content = content.replace('State<LeastPriceHomePage> createState() =>', 'ConsumerState<LeastPriceHomePage> createState() =>')
    content = content.replace('class _LeastPriceHomePageState extends State<LeastPriceHomePage>', 'class _LeastPriceHomePageState extends ConsumerState<LeastPriceHomePage>')
    if "import 'package:leastprice/features/home/home_search_provider.dart';" not in content:
        content = content.replace("import 'home_exports.dart';", "import 'home_exports.dart';\nimport 'package:leastprice/features/home/home_search_provider.dart';\nimport 'package:leastprice/features/home/home_search_view.dart';")

    # 2. Remove Variables
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
    content = re.sub(r'Timer\?\s+_smartSearchDebounce;', '', content)

    # Remove methods using exact text boundaries or regex
    # We will remove them by finding their signatures and the matching closing brace.
    def remove_method(text, method_name):
        pattern = r'(Future<void>|void)\s+' + method_name + r'\s*\([^)]*\)\s*(async\s*)?\{'
        match = re.search(pattern, text)
        if not match:
            return text
        start_idx = match.end() - 1
        count = 0
        in_string = False
        string_char = ''
        i = start_idx
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
                        return text[:match.start()] + text[i+1:]
            i += 1
        return text

    methods_to_remove = [
        '_performSerpSearch',
        '_loadMoreSearchResults',
        '_runSmartSearch',
        '_scheduleSmartSearch',
        '_clearSearch',
        '_submitComparisonSearch',
        '_clearSmartSearchState',
        '_selectSearchCity',
        '_handleSearchChanged'
    ]
    for method in methods_to_remove:
        content = remove_method(content, method)

    # Also remove `_searchController.addListener(_handleSearchChanged);` from initState
    content = content.replace('_searchController.addListener(_handleSearchChanged);', '')
    content = content.replace('_smartSearchDebounce?.cancel();', '')

    # 3. Fix the build method local variables
    content = re.sub(r'final hasQuery = _query.*?;\n', '', content)
    content = re.sub(r'final comparisonResults = _comparisonSearchResults;\n', '', content)
    content = re.sub(r'final comparisonDataSourceLabel = showComparisonsSection\s*\?\s*_comparisonSearchSourceLabel\s*:\s*_dataSource\.label;', 'final comparisonDataSourceLabel = _dataSource.label;', content)

    # 4. Replace the UI blocks
    # We will remove all `if (showComparisonsSection)` blocks, and inject the new one.
    
    # Because there are many scattered `showComparisonsSection` and `else if (showComparisonsSection)`, 
    # we can just use regex to remove them. But since they are nested slivers, regex is hard.
    # Instead, let's use string replacement for the exact chunks we know exist!
    
    # Let's just find the first `if (showComparisonsSection)` and replace it with the new block.
    # Then find all other `if (showComparisonsSection)` and `else if (showComparisonsSection)` and delete them.
    
    import sys
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Pre-processed")

if __name__ == '__main__':
    main()
