import os
import re

MAIN_FILE = 'lib/main.dart'
HELPERS_FILE = 'lib/core/utils/helpers.dart'

def extract_blocks_from_main():
    with open(MAIN_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Block 1: appLang to HomeCatalogSection
    b1_start = content.find("final ValueNotifier<String> appLang")
    b1_end = content.find("Future<void> main() async {")
    if b1_start == -1 or b1_end == -1:
        print("Could not find Block 1")
        return "", content
        
    # We need to find the end of HomeCatalogSection or just take until before main
    # Actually, we can just grab everything from b1_start to the end of the line before main
    block1 = content[b1_start:b1_end].strip()
    
    # Wait, there's also _isAdminDashboardRequest and _isAdminPathToken and _isAllowedAdminEmail right after main and LeastPriceApp.
    # It's better to just extract using regexes for all functions/enums/variables at the root level.
    return block1, content

def get_all_dart_files(root_dir):
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

# These need to be renamed
RENAME_MAP = {
    '_isAr': 'isAr',
    '_normalizedImageUrl': 'normalizedImageUrl',
    '_arabicAuthMessage': 'arabicAuthMessage',
    '_dateTimeValue': 'dateTimeValue',
    '_formatHealthTimestamp': 'formatHealthTimestamp',
    '_formatDealExpiryLabel': 'formatDealExpiryLabel',
    '_asMap': 'asMap',
    '_stringValue': 'stringValue',
    '_sameStringLists': 'sameStringLists',
    '_doubleValue': 'doubleValue',
    '_intValue': 'intValue',
    '_boolValue': 'boolValue',
    '_stringListValue': 'stringListValue',
    '_extractMarketplacePrice': 'extractMarketplacePrice',
    '_comparisonSearchSourceTypeFromString': 'comparisonSearchSourceTypeFromString',
    '_comparisonSearchChannelTypeFromString': 'comparisonSearchChannelTypeFromString',
    '_normalizeStoreIdToken': 'normalizeStoreIdToken',
    '_hostFromUrl': 'hostFromUrl',
    '_storeIdForHost': 'storeIdForHost',
    '_inferStoreIdFromUrl': 'inferStoreIdFromUrl',
    '_inferComparisonChannelType': 'inferComparisonChannelType',
    '_resolveStoreLogoUrl': 'resolveStoreLogoUrl',
    '_normalizeArabic': 'normalizeArabic',
    '_formatSaudiPhoneNumber': 'formatSaudiPhoneNumber',
    '_normalizeEmailAddress': 'normalizeEmailAddress',
    '_isAdminDashboardRequest': 'isAdminDashboardRequest',
    '_isAdminPathToken': 'isAdminPathToken',
    '_isAllowedAdminEmail': 'isAllowedAdminEmail',
}

def rename_in_content(content):
    for old, new in RENAME_MAP.items():
        # Replace occurrences of old with new
        # Be careful not to replace parts of other words
        content = re.sub(r'\b' + old + r'\b', new, content)
    return content

def add_import_if_missing(content, import_statement, search_terms=None):
    if import_statement in content:
        return content
        
    should_import = False
    if search_terms:
        for term in search_terms:
            if re.search(r'\b' + term + r'\b', content):
                should_import = True
                break
    else:
        should_import = True
        
    if should_import:
        # Find the last import
        import_idx = content.rfind("import '")
        if import_idx == -1:
            import_idx = content.rfind('import "')
            
        if import_idx != -1:
            end_line = content.find(';', import_idx)
            content = content[:end_line+1] + '\n' + import_statement + content[end_line+1:]
        else:
            content = import_statement + '\n' + content
            
    return content

def main():
    # 1. Read main.dart and extract the helpers
    with open(MAIN_FILE, 'r', encoding='utf-8') as f:
        main_content = f.read()
        
    # Find all root-level functions, enums, extensions, and variables starting with _ or some specific ones
    # We will just split main.dart manually based on what we know
    
    # The part before main()
    main_func_idx = main_content.find("Future<void> main() async {")
    before_main = main_content[:main_func_idx]
    
    # We need to preserve imports in main.dart
    # Let's find the last import in before_main
    last_import_idx = before_main.rfind("import ")
    last_import_end = before_main.find(";", last_import_idx) + 1
    
    imports_part = before_main[:last_import_end]
    helpers_part_1 = before_main[last_import_end:].strip()
    
    # The part after LeastPriceApp
    app_class_idx = main_content.find("class LeastPriceApp")
    app_class_end = -1
    
    # find the end of LeastPriceApp
    brace_count = 0
    in_class = False
    for i in range(app_class_idx, len(main_content)):
        if main_content[i] == '{':
            brace_count += 1
            in_class = True
        elif main_content[i] == '}':
            brace_count -= 1
            if in_class and brace_count == 0:
                app_class_end = i + 1
                break
                
    helpers_part_2 = main_content[app_class_end:].strip()
    
    # New main.dart content
    new_main_content = imports_part + "\n\n" + "import 'package:leastprice/core/utils/helpers.dart';\n\n" + main_content[main_func_idx:app_class_end] + "\n"
    new_main_content = rename_in_content(new_main_content)
    
    # Helper content
    helpers_content = """import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';

""" + helpers_part_1 + "\n\n" + helpers_part_2

    helpers_content = rename_in_content(helpers_content)
    
    os.makedirs(os.path.dirname(HELPERS_FILE), exist_ok=True)
    with open(HELPERS_FILE, 'w', encoding='utf-8') as f:
        f.write(helpers_content)
        
    with open(MAIN_FILE, 'w', encoding='utf-8') as f:
        f.write(new_main_content)
        
    # Now go through all files and rename + add imports
    all_files = get_all_dart_files('lib')
    
    # Identify which files need which imports
    # We will build a map of class names to their file paths
    import_map = {
        'ProductComparison': "import 'package:leastprice/data/models/product_comparison.dart';",
        'SearchResultItem': "import 'package:leastprice/data/models/search_result_item.dart';",
        'SmartSearchDiscoveryResult': "import 'package:leastprice/data/models/smart_search_discovery_result.dart';",
        'ProductCategoryCatalog': "import 'package:leastprice/data/models/product_category_catalog.dart';",
        '_SmartSearchCandidate': "import 'package:leastprice/data/models/smart_search_candidate.dart';",
        'SearchAutomationClient': "import 'package:leastprice/services/automation/search_automation_client.dart';",
        'AppPalette': "import 'package:leastprice/core/theme/app_palette.dart';",
        'LeastPriceDataConfig': "import 'package:leastprice/core/config/least_price_data_config.dart';",
        'AppBrandMark': "import 'package:leastprice/core/widgets/app_brand_mark.dart';",
        'UserSavingsProfile': "import 'package:leastprice/data/models/user_savings_profile.dart';",
        'FirestoreCatalogService': "import 'package:leastprice/data/repositories/firestore_catalog_service.dart';",
        'ProductRepository': "import 'package:leastprice/data/repositories/product_repository.dart';",
        'SerpApiShoppingSearchService': "import 'package:leastprice/services/api/serp_api_shopping_search_service.dart';",
        'AffiliateLinkService': "import 'package:leastprice/services/api/affiliate_link_service.dart';",
        'SmartMonitorService': "import 'package:leastprice/services/automation/smart_monitor_service.dart';",
        'SmartSearchDiscoveryService': "import 'package:leastprice/services/automation/smart_search_discovery_service.dart';",
        'ProductCategory': "import 'package:leastprice/data/models/product_category.dart';",
        'ExclusiveDeal': "import 'package:leastprice/data/models/exclusive_deal.dart';",
        'AdBannerItem': "import 'package:leastprice/data/models/ad_banner_item.dart';",
        'AdminProductDraft': "import 'package:leastprice/data/models/admin_product_draft.dart';",
        'ComparisonSearchResponse': "import 'package:leastprice/data/models/comparison_search_response.dart';",
        'ComparisonSearchResult': "import 'package:leastprice/data/models/comparison_search_result.dart';",
        'ComparisonSearchCacheEntry': "import 'package:leastprice/data/models/comparison_search_cache_entry.dart';",
        'ParsedCatalogPayload': "import 'package:leastprice/data/models/parsed_catalog_payload.dart';",
        'CatalogRefreshResult': "import 'package:leastprice/data/models/catalog_refresh_result.dart';",
        'ProductLoadResult': "import 'package:leastprice/data/models/product_load_result.dart';",
        'AutomationHealthStatus': "import 'package:leastprice/data/models/automation_health_status.dart';",
        'AuthGate': "import 'package:leastprice/features/auth/auth_gate.dart';",
        'AuthenticatedBootstrap': "import 'package:leastprice/features/auth/authenticated_bootstrap.dart';",
        'LoginScreen': "import 'package:leastprice/features/auth/login_screen.dart';",
        'AdminDashboardAuthGate': "import 'package:leastprice/features/admin/admin_dashboard_auth_gate.dart';",
        'AdminLoginScreen': "import 'package:leastprice/features/admin/admin_login_screen.dart';",
        'LeastPriceHomePage': "import 'package:leastprice/features/home/least_price_home_page.dart';",
    }
    
    helper_terms = list(RENAME_MAP.values()) + ['tr', 'appLang', 'requiredFieldMessage', 'validValueMessage', 'validUrlMessage', 'localizedCategoryLabelForId', 'localizedKnownLabel', 'HomeCatalogSection', 'ProductDataSource', 'SearchProviderType', 'ComparisonSearchSourceType', 'ComparisonSearchChannelType', 'formatPrice', 'formatAmountValue']
    
    for file_path in all_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        
        # Rename helpers
        content = rename_in_content(content)
        
        # Also fix _SmartSearchCandidate to SmartSearchCandidate
        content = re.sub(r'\b_SmartSearchCandidate\b', 'SmartSearchCandidate', content)
        
        # Add imports
        for class_name, import_stmt in import_map.items():
            search_term = class_name
            if class_name == '_SmartSearchCandidate':
                search_term = 'SmartSearchCandidate'
                
            if search_term in content and file_path.replace('\\', '/').split('/')[-1] != import_stmt.split('/')[-1].replace("';", ""):
                content = add_import_if_missing(content, import_stmt)
                
        content = add_import_if_missing(content, "import 'package:leastprice/core/utils/helpers.dart';", helper_terms)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == '__main__':
    main()
