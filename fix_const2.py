import re

files = [
    r'd:\leastprice\lib\features\home\coupons_paywall_section.dart',
    r'd:\leastprice\lib\features\home\header_section.dart',
    r'd:\leastprice\lib\features\home\metrics.dart',
    r'd:\leastprice\lib\features\home\plan_picker_section.dart',
    r'd:\leastprice\lib\features\home\search_suggestions_carousel.dart',
    r'd:\leastprice\lib\features\search\barcode_scanner_screen.dart',
    r'd:\leastprice\lib\features\home\least_price_home_page.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove const before AppPalette usages that were accidentally left
    content = content.replace('const AppPalette', 'AppPalette')
    content = content.replace('const  AppPalette', 'AppPalette')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
