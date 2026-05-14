import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leastprice/data/models/exclusive_deal.dart';

class DcmNetworkService {
  static const String _apiKey = '9f3f7b56f67428dc6a1beaedab104ebf29666a85ab0cd1b29a8354f8d57455cf';
  static const String _baseUrl = 'https://api.dcmnetwork.com/v1'; // مثال للرابط الأساسي

  Future<List<ExclusiveDeal>> fetchLatestOffers() async {
    try {
      // قمت بإضافة '&country=SA' لضمان جلب العروض السعودية فقط
      final response = await http.get(
        Uri.parse('$_baseUrl/offers?api_key=$_apiKey&country=SA'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // هنا نقوم بتحويل البيانات القادمة من DCM إلى تنسيق ExclusiveDeal الخاص بتطبيقك
        return data.map((item) => ExclusiveDeal(
          id: item['id']?.toString() ?? '',
          title: item['offer_name'] ?? '',
          imageUrl: item['image_url'] ?? '',
          dealUrl: item['tracking_url'] ?? '',
          // storeName and description are not in ExclusiveDeal model, so we combine them into title if needed or omit
          beforePrice: 0.0,
          afterPrice: 0.0,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          active: true,
        )).toList();
      }
    } catch (e) {
      // Error logging can be added here
    }
    return [];
  }
}
