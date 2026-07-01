import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the eye icon inside IconButton and give it a fixed color
    content = content.replace(
        "Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off)",
        "Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant)"
    )
    
    content = content.replace(
        "Icon(_obscurePasswordConfirm ? Icons.visibility : Icons.visibility_off)",
        "Icon(_obscurePasswordConfirm ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant)"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_file('lib/features/auth/login_screen.dart')
    fix_file('lib/features/auth/register_screen.dart')
except Exception as e:
    print(f"Error: {e}")
