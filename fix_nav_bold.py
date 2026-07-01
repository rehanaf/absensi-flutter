import re

def fix_bold(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove bold from active navigation bar item
    content = content.replace(
        "return TextStyle(color: lightColorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pliant');",
        "return TextStyle(color: lightColorScheme.primary, fontSize: 12, fontFamily: 'Pliant');"
    )
    
    content = content.replace(
        "return TextStyle(color: darkColorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pliant');",
        "return TextStyle(color: darkColorScheme.primary, fontSize: 12, fontFamily: 'Pliant');"
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_bold('lib/main.dart')
except Exception as e:
    print(f"Error: {e}")
