import os
import re

def get_all_dart_files(root_dir):
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def extract_declarations(content):
    declarations = []
    # Match class, enum, extension
    pattern = re.compile(r'^(?:abstract\s+)?(?:class|enum|extension)\s+([a-zA-Z0-9_]+)', re.MULTILINE)
    for match in pattern.finditer(content):
        declarations.append(match.group(1))
        
    # Also find top level functions if we wanted, but we put them in helpers.dart
    return declarations

def add_imports_to_file(file_path, content, required_imports):
    if not required_imports:
        return content
        
    existing_imports = set(re.findall(r"import\s+['\"]([^'\"]+)['\"];", content))
    
    imports_to_add = []
    for imp in required_imports:
        # Extract path from imp
        m = re.search(r"import\s+['\"]([^'\"]+)['\"];", imp)
        if m and m.group(1) not in existing_imports:
            imports_to_add.append(imp)
            
    if not imports_to_add:
        return content
        
    import_idx = content.rfind("import '")
    if import_idx == -1:
        import_idx = content.rfind('import "')
        
    if import_idx != -1:
        end_line = content.find(';', import_idx)
        content = content[:end_line+1] + '\n' + '\n'.join(imports_to_add) + content[end_line+1:]
    else:
        content = '\n'.join(imports_to_add) + '\n\n' + content
        
    return content

def main():
    dart_files = get_all_dart_files('lib')
    
    decl_map = {}
    
    # 1. Build map
    for file_path in dart_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        decls = extract_declarations(content)
        import_path = file_path.replace('\\', '/').replace('lib/', '')
        import_stmt = f"import 'package:leastprice/{import_path}';"
        
        for decl in decls:
            # exclude states
            if not decl.endswith('State') or decl == 'AutomationHealthStatus': 
                decl_map[decl] = import_stmt

    # 2. Add imports
    for file_path in dart_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        required_imports = set()
        
        # Check usages
        for decl, import_stmt in decl_map.items():
            # Don't import itself
            if import_stmt.replace("import 'package:leastprice/", "").replace("';", "") == file_path.replace('\\', '/').replace('lib/', ''):
                continue
                
            # Regex to match the declaration used as a word
            if re.search(r'\b' + decl + r'\b', content):
                required_imports.add(import_stmt)
                
        # Also ensure GlobalRuntimeErrorScreen is imported in main.dart
        if file_path.endswith('main.dart'):
            if '_GlobalRuntimeErrorScreen' in content:
                required_imports.add("import 'package:leastprice/core/widgets/global_runtime_error_screen.dart';")
                
        content = add_imports_to_file(file_path, content, required_imports)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
                
    print("Auto-imported missing declarations.")

if __name__ == '__main__':
    main()
