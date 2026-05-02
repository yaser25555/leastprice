import re

files = [
    r'd:\leastprice\lib\features\home\coupons_paywall_section.dart',
    r'd:\leastprice\lib\features\home\header_section.dart',
    r'd:\leastprice\lib\features\home\metrics.dart',
    r'd:\leastprice\lib\features\home\plan_picker_section.dart',
    r'd:\leastprice\lib\features\home\search_suggestions_carousel.dart',
    r'd:\leastprice\lib\features\search\barcode_scanner_screen.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove const before AppPalette usages
    content = re.sub(r'const\s+(TextStyle\([^)]*AppPalette)', r'\1', content)
    content = re.sub(r'const\s+(Icon\([^)]*AppPalette)', r'\1', content)
    content = re.sub(r'const\s+(Text\([^)]*AppPalette)', r'\1', content)
    # Generic catch-all for anything on the same line as AppPalette
    lines = content.split('\n')
    for i in range(len(lines)):
        if 'AppPalette' in lines[i]:
            # If the current line or previous line has const, it might be invalid
            lines[i] = lines[i].replace('const ', '')
            if i > 0 and 'const ' in lines[i-1]:
                lines[i-1] = lines[i-1].replace('const ', '')
            if i > 1 and 'const ' in lines[i-2]:
                lines[i-2] = lines[i-2].replace('const ', '')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
