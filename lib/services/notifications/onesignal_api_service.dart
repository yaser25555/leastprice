import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:leastprice/core/config/least_price_data_config.dart';

class OneSignalApiService {
  static const String _baseUrl = 'https://onesignal.com/api/v1/notifications';
  
  // Pass via `--dart-define=ONESIGNAL_REST_API_KEY=...` at build time.
  // Default is empty — admin panel will show an error if missing.
  static const String _restApiKey = String.fromEnvironment(
    'ONESIGNAL_REST_API_KEY',
    defaultValue: '',
  );

  static bool get hasApiKey => _restApiKey.isNotEmpty;

  static Future<bool> sendGlobalNotification({
    required String titleAr,
    required String bodyAr,
    required String titleEn,
    required String bodyEn,
    String? url,
  }) async {
    if (_restApiKey.isEmpty) {
      debugPrint('OneSignal REST API key is missing. '
          'Pass --dart-define=ONESIGNAL_REST_API_KEY=... at build time.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode({
          'app_id': LeastPriceDataConfig.oneSignalAppId,
          'included_segments': ['All'],
          'headings': {
            'en': titleEn,
            'ar': titleAr,
          },
          'contents': {
            'en': bodyEn,
            'ar': bodyAr,
          },
          if (url != null && url.isNotEmpty) 'url': url,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('OneSignal API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('OneSignal API Exception: $e');
      return false;
    }
  }
}
