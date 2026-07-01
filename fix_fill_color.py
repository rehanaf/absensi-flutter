import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fallback to catch all instances of surfaceContainerHighest
    content = content.replace(
        "fillColor: colorScheme.surfaceContainerHighest",
        "fillColor: colorScheme.onSurface.withOpacity(0.08)"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file('lib/features/auth/login_screen.dart')
fix_file('lib/features/auth/register_screen.dart')
