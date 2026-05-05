import re

def process(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # replace print( with debugPrint( or just ignore the avoid_print
    # Actually we can just add // ignore_for_file: avoid_print at the top
    if '// ignore_for_file: avoid_print' not in content:
        content = '// ignore_for_file: avoid_print\n' + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process(r'd:\leastprice\test_search.dart')
process(r'd:\leastprice\test_serper.dart')
