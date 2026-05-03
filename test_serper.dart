import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'iphone 14';
  final apiKey = 'f7fa2546aac3050cc7972a4265217d42c3c38ff4c';

  final uri = Uri.https('google.serper.dev', '/search');
  final response = await http.post(
    uri,
    headers: {
      'X-API-KEY': apiKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'q': query,
      'gl': 'sa',
      'hl': 'ar',
      'location': 'Saudi Arabia',
    }),
  );

  print('Status code: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final payload = jsonDecode(response.body);
    final organic = payload['organic'];
    if (organic is List) {
      print('Found ${organic.length} direct organic results');
      if (organic.isNotEmpty) {
        print('First result: ${organic.first['title']}');
      }
    } else {
      print('No organic array found');
    }
  } else {
    print('Error: ${response.body}');
  }
}
