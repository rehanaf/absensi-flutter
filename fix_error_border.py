import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the border: OutlineInputBorder(...) line and add error borders below it
    content = content.replace(
        "border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),",
        "border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),\n                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),\n                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 2)),"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_file('lib/features/auth/login_screen.dart')
    fix_file('lib/features/auth/register_screen.dart')
except Exception as e:
    print(f"Error: {e}")
