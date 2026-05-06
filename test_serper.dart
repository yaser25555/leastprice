// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'iphone 14';
  const apiKey = String.fromEnvironment('SERPER_API_KEY');
  if (apiKey.trim().isEmpty) {
    print('Pass SERPER_API_KEY with --dart-define to run this smoke test.');
    return;
  }

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
