import 'dart:async';
import 'dart:math' as math;

import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/search_result_item.dart';
import 'package:leastprice/data/models/smart_search_discovery_result.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/smart_search_candidate.dart';
import 'package:leastprice/services/automation/search_automation_client.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SmartSearchDiscoveryService {
  const SmartSearchDiscoveryService();

  Future<SmartSearchDiscoveryResult> discoverComparisons({
    required String query,
    required String selectedCategoryId,
    required List<ProductComparison> existingProducts,
  }) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.isEmpty) {
      return const SmartSearchDiscoveryResult(products: <ProductComparison>[]);
    }

    final searchClient = SearchAutomationClient.fromConfig();
    if (searchClient == null) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'لتفعيل البحث الذكي من الويب أضف مفتاح Serper أو Tavily عبر --dart-define.',
          'To enable smart web search, add a Serper or Tavily key using --dart-define.',
        ),
      );
    }

    final searchResults = await searchClient.search(
      _buildDiscoveryQuery(
        query: query,
        selectedCategoryId: selectedCategoryId,
      ),
    );

    final candidates = searchResults
        .map(
          (item) => _buildCandidate(
            item,
            query: query,
            selectedCategoryId: selectedCategoryId,
          ),
        )
        .whereType<SmartSearchCandidate>()
        .toList();

    if (candidates.length < 2) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'لم تتوفر بعد أسعار ويب كافية لتكوين بطاقة مقارنة جديدة، لذلك سنعتمد على القاعدة الحالية أو طلب الإضافة القادم.',
          'There are not enough web prices yet to build a new comparison card, so we will keep using the current database or the next queued request.',
        ),
      );
    }

    final suggestions = _buildSuggestedComparisons(
      query: query,
      candidates: candidates,
      existingProducts: existingProducts,
    );

    if (suggestions.isEmpty) {
      return SmartSearchDiscoveryResult(
        products: <ProductComparison>[],
        notice: tr(
          'نتائج الويب الحالية كانت قريبة من البيانات الموجودة مسبقاً، لذلك لم نضف بطاقة جديدة الآن.',
          'Current web results were too close to existing data, so no new card was added right now.',
        ),
      );
    }

    return SmartSearchDiscoveryResult(
      products: suggestions,
      notice: tr(
        'تم توليد ${suggestions.length} بطاقة ذكية من نتائج الويب حتى لو لم تكن موجودة في قاعدة البيانات.',
        '${suggestions.length} smart cards were generated from web results even though they were not in the database.',
      ),
    );
  }

  String _buildDiscoveryQuery({
    required String query,
    required String selectedCategoryId,
  }) {
    final categoryHint = selectedCategoryId == ProductCategoryCatalog.allId
        ? ''
        : '${ProductCategoryCatalog.lookup(selectedCategoryId).label} ';

    return '$query $categoryHintسعر مكونات السعودية '
        'site:amazon.sa OR site:noon.com OR site:nahdionline.com OR site:al-dawaa.com OR site:hungerstation.com OR site:jahez.net OR site:mrsool.co';
  }

  SmartSearchCandidate? _buildCandidate(
    SearchResultItem item, {
    required String query,
    required String selectedCategoryId,
  }) {
    final uri = Uri.tryParse(item.link);
    if (uri == null || !uri.hasAuthority) {
      return null;
    }

    final price = _extractPrice(item.title, item.snippet);
    if (price == null || price <= 0) {
      return null;
    }

    final cleanedName = _cleanResultTitle(item.title);
    if (cleanedName.isEmpty) {
      return null;
    }

    final inferredCategoryId = selectedCategoryId ==
            ProductCategoryCatalog.allId
        ? ProductCategoryCatalog.inferId('$query ${item.title} ${item.snippet}')
        : selectedCategoryId;
    final category = ProductCategoryCatalog.lookup(
      inferredCategoryId,
      fallbackLabel: 'مقارنة ذكية',
    );

    return SmartSearchCandidate(
      name: cleanedName,
      price: price,
      link: item.link,
      hostLabel: _hostLabel(uri.host),
      categoryId: category.id,
      categoryLabel: category.label,
      detail: _extractDetail(item.snippet, category.id),
    );
  }

  List<ProductComparison> _buildSuggestedComparisons({
    required String query,
    required List<SmartSearchCandidate> candidates,
    required List<ProductComparison> existingProducts,
  }) {
    final sorted = [...candidates]..sort((a, b) => a.price.compareTo(b.price));
    final suggestions = <ProductComparison>[];
    final seenFingerprints = <String>{};
    final rowCount = math.min(2, sorted.length ~/ 2);

    for (var index = 0; index < rowCount; index++) {
      final cheaper = sorted[index];
      final pricier = sorted[sorted.length - 1 - index];

      if (pricier.price <= cheaper.price) {
        continue;
      }

      final pairFingerprint = normalizeArabic(
        '${pricier.name}|${cheaper.name}|${cheaper.categoryId}',
      );
      if (!seenFingerprints.add(pairFingerprint)) {
        continue;
      }

      final detail = cheaper.detail ?? pricier.detail;
      final suggestion = ProductComparison(
        categoryId: cheaper.categoryId,
        categoryLabel: cheaper.categoryLabel,
        expensiveName: pricier.name,
        expensivePrice: pricier.price,
        expensiveImageUrl: '',
        alternativeName: cheaper.name,
        alternativePrice: cheaper.price,
        alternativeImageUrl: '',
        buyUrl: cheaper.link,
        rating: 0,
        reviewCount: 0,
        tags: [
          cheaper.categoryLabel,
          query,
          'بحث ذكي',
          cheaper.hostLabel,
        ],
        fragranceNotes: cheaper.categoryId == 'perfumes' ? detail : null,
        activeIngredients: cheaper.categoryId == 'perfumes' ? null : detail,
        localLocationLabel:
            cheaper.categoryId == 'restaurants' ? cheaper.hostLabel : null,
        localLocationUrl:
            cheaper.categoryId == 'restaurants' ? cheaper.link : null,
      );

      if (_isDuplicateSuggestion(suggestion, existingProducts)) {
        continue;
      }

      suggestions.add(suggestion);
    }

    return suggestions;
  }

  bool _isDuplicateSuggestion(
    ProductComparison suggestion,
    List<ProductComparison> existingProducts,
  ) {
    final expensiveToken = normalizeArabic(suggestion.expensiveName);
    final alternativeToken = normalizeArabic(suggestion.alternativeName);

    for (final product in existingProducts) {
      if (normalizeArabic(product.expensiveName) == expensiveToken &&
          normalizeArabic(product.alternativeName) == alternativeToken) {
        return true;
      }
    }

    return false;
  }

  String _cleanResultTitle(String title) {
    final raw = title.trim();
    if (raw.isEmpty) {
      return '';
    }

    final separators = [' | ', ' - ', ' ? ', ' ? ', ' ? '];
    for (final separator in separators) {
      final index = raw.indexOf(separator);
      if (index > 12) {
        return raw.substring(0, index).trim();
      }
    }

    return raw;
  }

  String? _extractDetail(String snippet, String categoryId) {
    final normalizedSnippet = snippet.trim();
    if (normalizedSnippet.isEmpty) {
      return null;
    }

    final patterns = <RegExp>[
      RegExp(
          r'(?:المكونات|المادة الفعالة|ingredients?|active ingredients?)[:\-]\s*([^.\n]{12,120})',
          caseSensitive: false),
      RegExp(r'(?:النوتة|النفحات|notes?)[:\-]\s*([^.\n]{12,120})',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalizedSnippet);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    if (categoryId == 'perfumes') {
      return _trimWords(normalizedSnippet, wordCount: 8);
    }

    if (categoryId == 'cosmetics' || categoryId == 'pharmacy') {
      return _trimWords(normalizedSnippet, wordCount: 10);
    }

    return null;
  }

  String _trimWords(String text, {required int wordCount}) {
    final words = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(wordCount)
        .toList();
    return words.join(' ');
  }

  String _hostLabel(String host) {
    final normalized = host.toLowerCase();
    if (normalized.contains('amazon')) return 'Amazon.sa';
    if (normalized.contains('noon')) return 'Noon';
    if (normalized.contains('nahdi')) return 'النهدي';
    if (normalized.contains('dawaa')) return 'الدواء';
    if (normalized.contains('hungerstation')) return 'HungerStation';
    if (normalized.contains('jahez')) return 'جاهز';
    if (normalized.contains('mrsool')) return 'مرسول';
    return host;
  }

  double? _extractPrice(String title, String snippet) {
    final text = '$title $snippet'.replaceAll(',', '');
    final patterns = [
      RegExp(
        r'(?:ر\.?\s?س|ريال|SAR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'([0-9]+(?:\.[0-9]{1,2})?)\s*(?:ر\.?\s?س|ريال|SAR)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }

    return null;
  }
}
