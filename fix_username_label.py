import re

def fix_login(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace(
        "? 'Username tidak boleh kosong' : null,",
        "? '${settings.identityLabel} tidak boleh kosong' : null,"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_register(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace(
        "? 'Username tidak boleh kosong' : null,",
        "? '${settings.identityLabel} tidak boleh kosong' : null,"
    )
    
    content = content.replace(
        "hintText: 'Username',",
        "hintText: settings.identityLabel,"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_login('lib/features/auth/login_screen.dart')
    fix_register('lib/features/auth/register_screen.dart')
except Exception as e:
    print(f"Error: {e}")
