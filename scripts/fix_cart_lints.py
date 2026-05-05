import re

filepath = r'd:\leastprice\lib\features\cart\shopping_cart_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

launch_pattern = r'  Future<void> _launchUrl\(String urlString\) async \{.*?\n  \}\n\n'
content = re.sub(launch_pattern, '', content, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Cart lints fixed.")
