import os
import re

def get_all_dart_files(root_dir):
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    dart_files = get_all_dart_files('lib')
    
    # 1. Collect all private classes that were split
    private_classes = set()
    for file_path in dart_files:
        if 'features' in file_path or 'main.dart' in file_path or 'widgets' in file_path:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # match `class _Name`
            # do not match `class _NameState extends State<Name>` because we want states to remain private
            for match in re.finditer(r'^class\s+(_[A-Za-z0-9_]+)(?:\s+extends|\s+implements|\s*\{)', content, re.MULTILINE):
                class_name = match.group(1)
                if not class_name.endswith('State'):
                    private_classes.add(class_name)
                    
            for match in re.finditer(r'^enum\s+(_[A-Za-z0-9_]+)', content, re.MULTILINE):
                enum_name = match.group(1)
                private_classes.add(enum_name)

    print(f"Found {len(private_classes)} private classes to publicize.")

    # 2. Replace them in all files
    for file_path in dart_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        
        for p_class in private_classes:
            public_class = p_class[1:] # remove leading _
            # Replace exactly the word
            content = re.sub(r'\b' + p_class + r'\b', public_class, content)
            
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

    print("Finished publicizing classes.")

if __name__ == '__main__':
    main()
