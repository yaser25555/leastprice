import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/search_result_item.dart';
import 'package:leastprice/core/utils/helpers.dart';

class SearchAutomationClient {
  const SearchAutomationClient._({
    required this.providerType,
    required this.apiKey,
  });

  final SearchProviderType providerType;
  final String apiKey;

  static SearchAutomationClient? fromConfig() {
    switch (LeastPriceDataConfig.searchProviderType) {
      case SearchProviderType.serper:
        final key = LeastPriceDataConfig.serperApiKey;
        if (key.trim().isEmpty) {
          return null;
        }
        return SearchAutomationClient._(
          providerType: SearchProviderType.serper,
          apiKey: key,
        );
      case SearchProviderType.tavily:
        final key = LeastPriceDataConfig.tavilyApiKey;
        if (key.trim().isEmpty) {
          return null;
        }
        return SearchAutomationClient._(
          providerType: SearchProviderType.tavily,
          apiKey: key,
        );
    }
  }

  Future<List<SearchResultItem>> search(String query) async {
    switch (providerType) {
      case SearchProviderType.serper:
        return _searchSerper(query);
      case SearchProviderType.tavily:
        return _searchTavily(query);
    }
  }

  Future<List<SearchResultItem>> _searchSerper(String query) async {
    final payload = await _postJson(
      Uri.parse('https://google.serper.dev/search'),
      headers: {
        'X-API-KEY': apiKey,
      },
      body: {
        'q': query,
        'gl': 'sa',
        'hl': 'ar',
        'num': 5,
      },
    );

    final organic = payload['organic'];
    if (organic is! List) {
      return const [];
    }

    return organic
        .map(
          (item) => SearchResultItem(
            title: stringValue(item['title']) ?? '',
            link: stringValue(item['link']) ?? '',
            snippet: stringValue(item['snippet']) ?? '',
          ),
        )
        .where((item) => item.link.isNotEmpty)
        .toList();
  }

  Future<List<SearchResultItem>> _searchTavily(String query) async {
    final payload = await _postJson(
      Uri.parse('https://api.tavily.com/search'),
      body: {
        'api_key': apiKey,
        'query': query,
        'search_depth': 'advanced',
        'max_results': 5,
        'include_answer': false,
      },
    );

    final results = payload['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .map(
          (item) => SearchResultItem(
            title: stringValue(item['title']) ?? '',
            link: stringValue(item['url']) ?? '',
            snippet: stringValue(item['content']) ?? '',
          ),
        )
        .where((item) => item.link.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    Map<String, String>? headers,
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unexpected status: ${response.statusCode}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}
