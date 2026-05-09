import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leastprice/core/config/least_price_data_config.dart';

class OneSignalApiService {
  static const String _baseUrl = 'https://onesignal.com/api/v1/notifications';
  
  // We'll pass the REST API Key here. In a real production app, 
  // you might want to fetch this from Firebase Remote Config or a secure function.
  static const String _restApiKey = 'os_v2_app_ofjrn7at2bh65mhyqyfu2og64yqgeyfidt6er2mz4c3esbgv2hdvsiaxeg7pwxbjuvu2gbvc53aqaw7itw5rs772stjxo3oflihysai';

  static Future<bool> sendGlobalNotification({
    required String titleAr,
    required String bodyAr,
    required String titleEn,
    required String bodyEn,
    String? url,
  }) async {
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
        print('OneSignal API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('OneSignal API Exception: $e');
      return false;
    }
  }
}
