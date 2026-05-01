import os
import re

SOURCE_FILE = 'lib/main.dart'

COMMON_IMPORTS = """import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/widgets/app_brand_mark.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/models/automation_health_status.dart';
import 'package:leastprice/data/models/product_load_result.dart';
import 'package:leastprice/data/models/catalog_refresh_result.dart';
import 'package:leastprice/data/models/search_result_item.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/comparison_search_cache_entry.dart';
import 'package:leastprice/data/models/comparison_search_response.dart';
import 'package:leastprice/data/models/parsed_catalog_payload.dart';
import 'package:leastprice/data/models/smart_search_discovery_result.dart';
import 'package:leastprice/data/models/smart_search_candidate.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/product_category.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/admin_product_draft.dart';
import 'package:leastprice/services/api/serp_api_shopping_search_service.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/services/automation/smart_monitor_service.dart';
import 'package:leastprice/services/automation/search_automation_client.dart';
import 'package:leastprice/services/automation/smart_search_discovery_service.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/data/repositories/product_repository.dart';
"""

# Map of Class/Widget Name to its destination file
CLASS_MAP = {
    # Auth
    '_AuthenticatedBootstrapState': 'lib/features/auth/authenticated_bootstrap.dart',
    '_LoginScreenState': 'lib/features/auth/login_screen.dart',
    '_LegacyAnonymousSessionCleanupScreen': 'lib/features/auth/legacy_anonymous_session_cleanup_screen.dart',
    '_LegacyAnonymousSessionCleanupScreenState': 'lib/features/auth/legacy_anonymous_session_cleanup_screen.dart',
    '_EmailVerificationPendingScreen': 'lib/features/auth/email_verification_pending_screen.dart',
    '_EmailVerificationPendingScreenState': 'lib/features/auth/email_verification_pending_screen.dart',
    'PendingAuthSession': 'lib/features/auth/pending_auth_session.dart',
    '_AuthLoadingScreen': 'lib/features/auth/auth_loading_screen.dart',
    '_FirebaseSetupScreen': 'lib/features/auth/firebase_setup_screen.dart',
    '_AuthBootstrapErrorScreen': 'lib/features/auth/auth_bootstrap_error_screen.dart',

    # Admin
    '_AdminLoginScreenState': 'lib/features/admin/admin_login_screen.dart',
    '_AdminAccessDeniedScreen': 'lib/features/admin/admin_access_denied_screen.dart',
    'AdminDashboardScreen': 'lib/features/admin/admin_dashboard_screen.dart',
    '_AdminDashboardBody': 'lib/features/admin/admin_dashboard_screen.dart',
    '_AdminDashboardBodyState': 'lib/features/admin/admin_dashboard_screen.dart',
    '_AdminSimpleBannersPanel': 'lib/features/admin/admin_simple_banners_panel.dart',
    '_AdminSimpleBannersPanelState': 'lib/features/admin/admin_simple_banners_panel.dart',
    '_AdminSimpleProductsPanel': 'lib/features/admin/admin_simple_products_panel.dart',
    '_AdminSimpleProductsPanelState': 'lib/features/admin/admin_simple_products_panel.dart',
    'AdminControlCenter': 'lib/features/admin/admin_control_center.dart',
    '_AdminBannerManagerPanel': 'lib/features/admin/admin_banner_manager_panel.dart',
    '_AdminBannerManagerPanelState': 'lib/features/admin/admin_banner_manager_panel.dart',
    '_AdminProductManagerPanel': 'lib/features/admin/admin_product_manager_panel.dart',
    '_AdminProductManagerPanelState': 'lib/features/admin/admin_product_manager_panel.dart',
    '_AdminDashboardSectionCard': 'lib/features/admin/admin_dashboard_section_card.dart',
    '_AdminBannersTable': 'lib/features/admin/admin_banners_table.dart',
    '_AdminBannersTableState': 'lib/features/admin/admin_banners_table.dart',
    '_AdminProductsTable': 'lib/features/admin/admin_products_table.dart',
    '_AdminProductsTableState': 'lib/features/admin/admin_products_table.dart',
    '_AdminExclusiveDealsTable': 'lib/features/admin/admin_exclusive_deals_table.dart',
    '_AdminExclusiveDealsTableState': 'lib/features/admin/admin_exclusive_deals_table.dart',
    '_AdminBuildFailurePanel': 'lib/features/admin/admin_build_failure_panel.dart',
    '_AdminStatusChip': 'lib/features/admin/admin_status_chip.dart',
    '_AdminNetworkThumbnail': 'lib/features/admin/admin_network_thumbnail.dart',
    '_AdminBannerEditorDialog': 'lib/features/admin/admin_banner_editor_dialog.dart',
    '_AdminBannerEditorDialogState': 'lib/features/admin/admin_banner_editor_dialog.dart',
    '_AdminProductEditorDialog': 'lib/features/admin/admin_product_editor_dialog.dart',
    '_AdminProductEditorDialogState': 'lib/features/admin/admin_product_editor_dialog.dart',
    '_AdminExclusiveDealEditorDialog': 'lib/features/admin/admin_exclusive_deal_editor_dialog.dart',
    '_AdminExclusiveDealEditorDialogState': 'lib/features/admin/admin_exclusive_deal_editor_dialog.dart',
    '_AdminAddProductDialog': 'lib/features/admin/admin_add_product_dialog.dart',
    '_AdminAddProductDialogState': 'lib/features/admin/admin_add_product_dialog.dart',

    # Home
    'LeastPriceHomePage': 'lib/features/home/least_price_home_page.dart',
    '_LeastPriceHomePageState': 'lib/features/home/least_price_home_page.dart',
    '_StatusBanner': 'lib/features/home/status_banner.dart',
    '_ComparisonSearchPlaceholder': 'lib/features/home/comparison_search_placeholder.dart',
    '_ComparisonSearchResultCard': 'lib/features/home/comparison_search_result_card.dart',
    '_ComparisonImageFallback': 'lib/features/home/comparison_image_fallback.dart',
    '_HeaderSection': 'lib/features/home/header_section.dart',
    '_CompactHeaderSection': 'lib/features/home/header_section.dart',
    '_CompactMetricPill': 'lib/features/home/header_metrics.dart',
    '_CompactStatPill': 'lib/features/home/header_metrics.dart',
    '_ComparisonSearchBarSection': 'lib/features/home/comparison_search_bar_section.dart',
    '_SearchInfoPill': 'lib/features/home/search_info_pill.dart',
    '_BannerCarousel': 'lib/features/home/banner_carousel.dart',
    '_BannerCarouselState': 'lib/features/home/banner_carousel.dart',
    '_AdBannersSection': 'lib/features/home/ad_banners_section.dart',
    '_ExclusiveDealsCarousel': 'lib/features/home/exclusive_deals_carousel.dart',
    '_ExclusiveDealsCarouselState': 'lib/features/home/exclusive_deals_carousel.dart',
    '_ExclusiveDealCard': 'lib/features/home/exclusive_deal_card.dart',
    'ComparisonCard': 'lib/features/home/comparison_card.dart',
    'ProductPane': 'lib/features/home/product_pane.dart',
    '_RatingSummary': 'lib/features/home/rating_summary.dart',
    '_RatingStars': 'lib/features/home/rating_summary.dart',
    '_ComparisonInsights': 'lib/features/home/comparison_insights.dart',
    '_InsightRow': 'lib/features/home/comparison_insights.dart',
    '_SavingBadge': 'lib/features/home/badges.dart',
    '_SuperSavingBadge': 'lib/features/home/badges.dart',
    '_OriginalOnSaleBadge': 'lib/features/home/badges.dart',
    '_InviteMetric': 'lib/features/home/metrics.dart',
    '_StatPill': 'lib/features/home/metrics.dart',
    '_BackgroundBubble': 'lib/features/home/background_bubble.dart',
    '_EmptyState': 'lib/features/home/empty_state.dart',
    '_AutomatedComparisonBadge': 'lib/features/home/automated_comparison_badge.dart',
    '_HomeSectionSwitcher': 'lib/features/home/home_section_switcher.dart',
    '_HomeSectionSwitcherButton': 'lib/features/home/home_section_switcher.dart',
    '_ExclusiveDealsSection': 'lib/features/home/exclusive_deals_section.dart',
    '_ExclusiveDealsSectionState': 'lib/features/home/exclusive_deals_section.dart',
    '_RateAlternativeDialog': 'lib/features/home/rate_alternative_dialog.dart',
    '_RateAlternativeDialogState': 'lib/features/home/rate_alternative_dialog.dart',
}

def get_class_block(content, class_name):
    # Regex to find the start of the class
    pattern = re.compile(r'^class\s+' + class_name + r'\b.*?\{', re.MULTILINE | re.DOTALL)
    match = pattern.search(content)
    if not match:
        return None, None
    
    start_idx = match.start()
    brace_count = 0
    in_string = False
    string_char = ''
    escape = False
    
    end_idx = -1
    for i in range(match.end() - 1, len(content)):
        c = content[i]
        
        if escape:
            escape = False
            continue
            
        if c == '\\':
            escape = True
            continue
            
        if in_string:
            if c == string_char:
                in_string = False
        else:
            if c == '"' or c == "'":
                in_string = True
                string_char = c
            elif c == '{':
                brace_count += 1
            elif c == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_idx = i + 1
                    break
    
    if end_idx != -1:
        return start_idx, end_idx
    return None, None

def main():
    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    extracted_files = set()
    
    for class_name, dest_file in CLASS_MAP.items():
        start_idx, end_idx = get_class_block(content, class_name)
        if start_idx is not None and end_idx is not None:
            class_code = content[start_idx:end_idx]
            
            # Remove from content
            content = content[:start_idx] + content[end_idx:]
            
            # Write or append to file
            os.makedirs(os.path.dirname(dest_file), exist_ok=True)
            
            # Read existing file to check if COMMON_IMPORTS is there
            file_exists = os.path.exists(dest_file)
            existing_content = ''
            if file_exists:
                with open(dest_file, 'r', encoding='utf-8') as f:
                    existing_content = f.read()
                    
            with open(dest_file, 'a', encoding='utf-8') as f:
                if not file_exists or "import 'dart:async';" not in existing_content:
                    # Write at the beginning if file is new or missing imports
                    f.write(COMMON_IMPORTS + '\n')
                f.write(class_code + '\n\n')
            
            extracted_files.add(dest_file)
            print(f'Extracted {class_name} to {dest_file}')

    # Remove AppPalette if still exists
    start_idx, end_idx = get_class_block(content, 'AppPalette')
    if start_idx is not None and end_idx is not None:
        content = content[:start_idx] + content[end_idx:]
        print('Removed AppPalette from main.dart')

    with open(SOURCE_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
