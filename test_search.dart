import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'iphone 14';
  final apiKey = '8f5e0a4c11cb0e6972f549ee390b083531ca2545ef1c02593c20efae8e917861';

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
        print('First result: ${shoppingResults.first['title']} - ${shoppingResults.first['price']}');
      }
    } else {
      print('No shopping_results array found');
      print(payload.keys);
    }
  } else {
    print('Error: ${response.body}');
  }
}
