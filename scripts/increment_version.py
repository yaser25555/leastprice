import yaml
import sys

def increment_version():
    with open('pubspec.yaml', 'r') as f:
        lines = f.readlines()
    
    with open('pubspec.yaml', 'w') as f:
        for line in lines:
            if line.startswith('version:'):
                parts = line.split(':')
                version_full = parts[1].strip()
                
                # Format: major.minor.patch+build
                if '+' in version_full:
                    version_base, build_number = version_full.split('+')
                    new_build = int(build_number) + 1
                    new_version = f"{version_base}+{new_build}"
                else:
                    new_version = f"{version_full}+1"
                
                f.write(f"version: {new_version}\n")
                print(f"🚀 Version incremented to: {new_version}")
            else:
                f.write(line)

if __name__ == "__main__":
    increment_version()
