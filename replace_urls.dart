import 'dart:io';

void main() {
  final files = [
    'lib/features/home/popular_stores_section.dart',
    'lib/features/home/brand_offers_section.dart'
  ];
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    content = content.replaceAllMapped(
      RegExp(r"https://logo\.clearbit\.com/([^']+)"),
      (match) => 'https://www.google.com/s2/favicons?domain=${match.group(1)}&sz=128'
    );
    file.writeAsStringSync(content);
    print('Updated $path');
  }
}
