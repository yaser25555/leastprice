import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Replace .withOpacity(x) with .withValues(alpha: x)
    content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)

    # 2. Replace Share.share( to SharePlus.instance.share(
    content = re.sub(r'\bShare\.share\(', r'SharePlus.instance.share(', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    for root, dirs, files in os.walk(r'd:\leastprice\lib'):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
