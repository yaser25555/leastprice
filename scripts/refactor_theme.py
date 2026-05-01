import os
import subprocess
import re

def main():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'lib'))
    
    # 1. Update app_palette.dart
    app_palette_path = os.path.join(lib_dir, 'core', 'theme', 'app_palette.dart')
    with open(app_palette_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Change "static const Color" to "static Color get"
    # But first, we inject the ValueNotifier
    new_content = "import 'package:flutter/material.dart';\n\n"
    new_content += "final ValueNotifier<bool> isFeminineTheme = ValueNotifier<bool>(false);\n\n"
    
    # We will map colors:
    # navy -> azure
    # orange -> pink
    # We'll use a dynamic getter.
    # To do this safely, we will replace `static const Color name = Color(hex);`
    # with `static Color get name => isFeminineTheme.value ? Color(feminineHex) : Color(hex);`
    
    # Let's define the color mappings manually to ensure good design
    lines = content.split('\n')
    out_lines = []
    
    for line in lines:
        if 'import' in line:
            continue
        if 'static const Color navy =' in line:
            out_lines.append('  static Color get navy => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF1B2F5E);')
        elif 'static const Color deepNavy =' in line:
            out_lines.append('  static Color get deepNavy => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF12284D);')
        elif 'static const Color softNavy =' in line:
            out_lines.append('  static Color get softNavy => isFeminineTheme.value ? const Color(0xFF3388CC) : const Color(0xFF2C4C84);')
        elif 'static const Color lightNavy =' in line:
            out_lines.append('  static Color get lightNavy => isFeminineTheme.value ? const Color(0xFF55AADD) : const Color(0xFF3B639E);')
        elif 'static const Color orange =' in line:
            out_lines.append('  static Color get orange => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);')
        elif 'static const Color paleOrange =' in line:
            out_lines.append('  static Color get paleOrange => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFFFB978);')
        elif 'static const Color softOrange =' in line:
            out_lines.append('  static Color get softOrange => isFeminineTheme.value ? const Color(0xFF004C8C) : const Color(0xFF213C6E);')
        elif 'static const Color turquoise =' in line:
            out_lines.append('  static Color get turquoise => isFeminineTheme.value ? const Color(0xFFE040FB) : const Color(0xFF35C9C4);')
        elif 'static const Color softTurquoise =' in line:
            out_lines.append('  static Color get softTurquoise => isFeminineTheme.value ? const Color(0xFFEA80FC) : const Color(0xFF7DE7E2);')
        elif 'static const Color comparisonEmerald =' in line:
            out_lines.append('  static Color get comparisonEmerald => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);')
        elif 'static const Color comparisonSoftEmerald =' in line:
            out_lines.append('  static Color get comparisonSoftEmerald => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2B4A80);')
        elif 'static const Color comparisonBorder =' in line:
            out_lines.append('  static Color get comparisonBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFF3A866);')
        elif 'static const Color dealsRed =' in line:
            out_lines.append('  static Color get dealsRed => isFeminineTheme.value ? const Color(0xFFFF4081) : const Color(0xFFE8711A);')
        elif 'static const Color dealsSoftRed =' in line:
            out_lines.append('  static Color get dealsSoftRed => isFeminineTheme.value ? const Color(0xFF005A9C) : const Color(0xFF2A4A82);')
        elif 'static const Color dealsBorder =' in line:
            out_lines.append('  static Color get dealsBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFF2A776);')
        elif 'static const Color shellBackground =' in line:
            out_lines.append('  static Color get shellBackground => isFeminineTheme.value ? const Color(0xFF003F7A) : const Color(0xFF162B52);')
        elif 'static const Color cardBackground =' in line:
            out_lines.append('  static Color get cardBackground => isFeminineTheme.value ? const Color(0xFF004C8C) : const Color(0xFF1C345F);')
        elif 'static const Color cardBorder =' in line:
            out_lines.append('  static Color get cardBorder => isFeminineTheme.value ? const Color(0xFFFF80AB) : const Color(0xFFEA9A58);')
        elif 'static const Color panelText =' in line:
            out_lines.append('  static Color get panelText => isFeminineTheme.value ? const Color(0xFFFFE4FF) : const Color(0xFF8BEDEA);')
        elif 'static const Color mutedText =' in line:
            out_lines.append('  static Color get mutedText => isFeminineTheme.value ? const Color(0xFFFFB3FF) : const Color(0xFF63D6D2);')
        elif 'static const Color shadow =' in line:
            out_lines.append('  static Color get shadow => isFeminineTheme.value ? const Color(0x14005A9C) : const Color(0x141B2F5E);')
        
        elif 'static const LinearGradient gradientWarmCta' in line:
            out_lines.append('  static LinearGradient get gradientWarmCta => LinearGradient(')
        elif 'static const LinearGradient gradientWarmSoft' in line:
            out_lines.append('  static LinearGradient get gradientWarmSoft => LinearGradient(')
        elif 'static const LinearGradient gradientSky' in line:
            out_lines.append('  static LinearGradient get gradientSky => LinearGradient(')
        elif 'const [' in line and 'colors:' in line and 'static const LinearGradient' not in line:
            out_lines.append(line.replace('const [', '['))
        elif 'static const Color' in line:
            # Change any other remaining static const Colors
            match = re.search(r'static const Color (\w+) = (.*);', line)
            if match:
                name = match.group(1)
                val = match.group(2)
                out_lines.append(f'  static Color get {name} => isFeminineTheme.value ? {val} : {val};')
            else:
                out_lines.append(line)
        else:
            out_lines.append(line)
            
    with open(app_palette_path, 'w', encoding='utf-8') as f:
        f.write(new_content + '\n'.join(out_lines))
        
    print("app_palette.dart updated.")

    # 2. Iterate removing invalid consts using flutter analyze
    project_dir = os.path.abspath(os.path.join(lib_dir, '..'))
    
    max_iters = 10
    for i in range(max_iters):
        print(f"Running flutter analyze iteration {i+1}...")
        result = subprocess.run(['flutter', 'analyze'], cwd=project_dir, capture_output=True, text=True, shell=True)
        
        output = result.stdout + "\n" + result.stderr
        
        fixes = 0
        lines_changed = {}
        
        # Look for typical constant errors
        # Example:  error - Arguments of a constant creation must be constant expressions - lib\features\home\least_price_home_page.dart:121:28 - non_constant_identifier_value
        # Example:  error - Constant values can't have a non-constant operand - lib\main.dart:55:12 - ...
        
        # Regex to match flutter analyze output line format
        pattern = r'error - (.*?) - (.*?):(\d+):(\d+) - (.*?)$'
        
        for analyze_line in output.split('\n'):
            match = re.search(pattern, analyze_line.strip())
            if match:
                file_rel = match.group(2).strip()
                if not file_rel.endswith('.dart'):
                    continue
                    
                err_code = match.group(5).strip()
                if err_code in ['non_constant_identifier_value', 'invalid_constant', 'const_with_non_constant_argument']:
                    line_num = int(match.group(3))
                    
                    file_path = os.path.join(project_dir, file_rel)
                    if not os.path.exists(file_path):
                        continue
                    
                    if file_path not in lines_changed:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            lines_changed[file_path] = f.readlines()
                            
                    # Remove 'const' from that line (if present) or the lines immediately above it
                    target_lines = lines_changed[file_path]
                    
                    # Look around the exact line for 'const '
                    found_const = False
                    for offset in range(0, -3, -1):
                        idx = (line_num - 1) + offset
                        if idx >= 0 and idx < len(target_lines):
                            if 'const ' in target_lines[idx]:
                                target_lines[idx] = target_lines[idx].replace('const ', '')
                                found_const = True
                                break
                    
                    # Sometimes the word 'const' is not directly present if it's inferred from an outer const
                    # In that case, we need to trace up to the nearest 'const' keyword and remove it.
                    if not found_const:
                        for idx in range(line_num - 1, max(-1, line_num - 20), -1):
                            if 'const ' in target_lines[idx]:
                                target_lines[idx] = target_lines[idx].replace('const ', '', 1)
                                found_const = True
                                break

                    if found_const:
                        fixes += 1
                        
        if fixes == 0:
            print("No more constant errors found!")
            break
            
        print(f"Applied {fixes} const removals.")
        for file_path, f_lines in lines_changed.items():
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(f_lines)

    print("Refactoring completed.")

if __name__ == '__main__':
    main()
