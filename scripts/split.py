import os
import re

SOURCE_FILE = 'lib/main.dart'

COMMON_IMPORTS = """import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
"""

# Map of Class/Widget Name to its destination file
CLASS_MAP = {
    'AppBrandMark': 'lib/core/widgets/app_brand_mark.dart',
    '_GlobalRuntimeErrorScreen': 'lib/core/widgets/global_runtime_error_screen.dart',
    'AuthGate': 'lib/features/auth/auth_gate.dart',
    'AuthenticatedBootstrap': 'lib/features/auth/authenticated_bootstrap.dart',
    'LoginScreen': 'lib/features/auth/login_screen.dart',
    'AdminDashboardAuthGate': 'lib/features/admin/admin_dashboard_auth_gate.dart',
    'AdminLoginScreen': 'lib/features/admin/admin_login_screen.dart',
    'LeastPriceDataConfig': 'lib/core/config/least_price_data_config.dart',
}

def get_class_block(content, class_name):
    # Regex to find the start of the class
    pattern = re.compile(r'^class\s+' + class_name + r'\b.*?\{', re.MULTILINE | re.DOTALL)
    match = pattern.search(content)
    if not match:
        return None, None
    
    start_idx = match.start()
    brace_count = 0
    in_string = False
    string_char = ''
    escape = False
    
    end_idx = -1
    for i in range(match.end() - 1, len(content)):
        c = content[i]
        
        if escape:
            escape = False
            continue
            
        if c == '\\':
            escape = True
            continue
            
        if in_string:
            if c == string_char:
                in_string = False
        else:
            if c == '"' or c == "'":
                in_string = True
                string_char = c
            elif c == '{':
                brace_count += 1
            elif c == '}':
                brace_count -= 1
                if brace_count == 0:
                    end_idx = i + 1
                    break
    
    if end_idx != -1:
        return start_idx, end_idx
    return None, None

def main():
    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    extracted_files = []
    
    for class_name, dest_file in CLASS_MAP.items():
        start_idx, end_idx = get_class_block(content, class_name)
        if start_idx is not None and end_idx is not None:
            class_code = content[start_idx:end_idx]
            
            # Remove from content
            content = content[:start_idx] + content[end_idx:]
            
            # Write to new file
            os.makedirs(os.path.dirname(dest_file), exist_ok=True)
            with open(dest_file, 'w', encoding='utf-8') as f:
                f.write(COMMON_IMPORTS + '\n')
                # Try to import palette if not in palette
                if class_name != 'AppPalette':
                    f.write("import 'package:leastprice/core/theme/app_palette.dart';\n")
                f.write(class_code + '\n')
            
            extracted_files.append(dest_file)
            print(f'Extracted {class_name} to {dest_file}')

    # Add imports to main.dart
    imports_to_add = ""
    for dest_file in extracted_files:
        # Convert path to package import format
        import_path = dest_file.replace('lib/', '').replace('\\', '/')
        imports_to_add += f"import '{import_path}';\n"
        
    # Insert imports after firebase_options import
    if imports_to_add:
        insert_pos = content.find("import 'firebase_options.dart';")
        if insert_pos != -1:
            end_of_line = content.find('\n', insert_pos)
            content = content[:end_of_line+1] + imports_to_add + content[end_of_line+1:]

    with open(SOURCE_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
