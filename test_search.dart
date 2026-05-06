// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'iphone 14';
  const apiKey = String.fromEnvironment('SERPAPI_KEY');
  if (apiKey.trim().isEmpty) {
    print('Pass SERPAPI_KEY with --dart-define to run this smoke test.');
    return;
  }

  final uri = Uri.https('serpapi.com', '/search.json', {
    'engine': 'google_shopping',
    'q': query,
    'location': 'Saudi Arabia',
    'gl': 'sa',
    'hl': 'ar',
    'api_key': apiKey,
  });

  print('Testing SerpAPI direct connection...');
  final response = await http.get(uri);
  print('Status code: ${response.statusCode}');

  if (response.statusCode == 200) {
    final payload = jsonDecode(response.body);
    final shoppingResults = payload['shopping_results'];
    if (shoppingResults is List) {
      print('Found ${shoppingResults.length} direct shopping results');
      if (shoppingResults.isNotEmpty) {
        print(
            'First result: ${shoppingResults.first['title']} - ${shoppingResults.first['price']}');
      }
    } else {
      print('No shopping_results array found');
      print(payload.keys);
    }
  } else {
    print('Error: ${response.body}');
  }
}
