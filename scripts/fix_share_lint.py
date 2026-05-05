import re

filepaths = [
    r'd:\leastprice\lib\features\home\exclusive_deal_card.dart',
    r'd:\leastprice\lib\features\home\least_price_home_page.dart'
]

for filepath in filepaths:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Revert back to Share.share
    content = content.replace('SharePlus.instance.share', 'Share.share')
    
    # Add ignore comment
    # We can just add // ignore: deprecated_member_use right before the Share.share line
    content = re.sub(r'([ \t]+)Share\.share\(', r'\1// ignore: deprecated_member_use\n\1Share.share(', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

print("Share lints fixed.")
