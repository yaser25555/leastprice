import os
import re

def process_file(filepath):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    new_content = re.sub(
        r"https://logo\.clearbit\.com/([^']+)",
        r"https://www.google.com/s2/favicons?domain=\1&sz=128",
        content
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated {filepath}")

process_file('lib/features/home/popular_stores_section.dart')
process_file('lib/features/home/brand_offers_section.dart')
