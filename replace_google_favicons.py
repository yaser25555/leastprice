import os
import re

directories = [
    'lib/features/home/popular_stores_section.dart',
    'lib/features/home/brand_offers_section.dart'
]

pattern = re.compile(r"https://www\.google\.com/s2/favicons\?domain=([^&]+)&sz=128")

for filepath in directories:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = pattern.sub(r"https://icon.horse/icon/\1", content)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"File not found: {filepath}")
