import os

def create_barrel(directory, barrel_name):
    files = [f for f in os.listdir(directory) if f.endswith('.dart') and f != barrel_name]
    exports = [f"export '{f}';" for f in files]
    
    with open(os.path.join(directory, barrel_name), 'w', encoding='utf-8') as f:
        f.write('\n'.join(exports) + '\n')
        
    return files

def inject_import(file_path, import_stmt):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if import_stmt in content:
        return
        
    import_idx = content.rfind("import '")
    if import_idx == -1:
        import_idx = content.rfind('import "')
        
    if import_idx != -1:
        end_line = content.find(';', import_idx)
        content = content[:end_line+1] + '\n' + import_stmt + content[end_line+1:]
    else:
        content = import_stmt + '\n\n' + content
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    # 1. Create barrels
    home_files = create_barrel('lib/features/home', 'home_exports.dart')
    auth_files = create_barrel('lib/features/auth', 'auth_exports.dart')
    admin_files = create_barrel('lib/features/admin', 'admin_exports.dart')
    
    # 2. Inject barrels into respective directory files
    for f in home_files:
        inject_import(os.path.join('lib/features/home', f), "import 'home_exports.dart';")
        inject_import(os.path.join('lib/features/home', f), "import 'package:leastprice/features/admin/admin_exports.dart';")
        
    for f in auth_files:
        inject_import(os.path.join('lib/features/auth', f), "import 'auth_exports.dart';")
        
    for f in admin_files:
        inject_import(os.path.join('lib/features/admin', f), "import 'admin_exports.dart';")
        
    # 3. Inject global fixes
    inject_import('lib/main.dart', "import 'package:leastprice/core/widgets/global_runtime_error_screen.dart';")
    
    print("Barrels created and imports injected.")

if __name__ == '__main__':
    main()
