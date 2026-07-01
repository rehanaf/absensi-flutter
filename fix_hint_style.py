import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the floatingLabelBehavior: FloatingLabelBehavior.never, line and add hintStyle below it
    content = content.replace(
        "floatingLabelBehavior: FloatingLabelBehavior.never,",
        "floatingLabelBehavior: FloatingLabelBehavior.never,\n                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_file('lib/features/auth/login_screen.dart')
    fix_file('lib/features/auth/register_screen.dart')
except Exception as e:
    print(f"Error: {e}")
