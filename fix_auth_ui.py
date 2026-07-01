import re
import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix emojis to Material Icons
    content = content.replace("Text('👤', style: TextStyle(fontSize: 18))", "Icon(Icons.person)")
    content = content.replace("Text('🔒', style: TextStyle(fontSize: 18))", "Icon(Icons.lock)")
    content = content.replace("Text('📧', style: TextStyle(fontSize: 18))", "Icon(Icons.email)")
    content = content.replace("Text('📝', style: TextStyle(fontSize: 18))", "Icon(Icons.badge)")
    content = content.replace("Text('🔐', style: TextStyle(fontSize: 18))", "Icon(Icons.lock_outline)")
    content = content.replace("Text(_obscurePassword ? '👁️' : '🙈', style: const TextStyle(fontSize: 18))", "Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off)")
    content = content.replace("Text(_obscurePasswordConfirm ? '👁️' : '🙈', style: const TextStyle(fontSize: 18))", "Icon(_obscurePasswordConfirm ? Icons.visibility : Icons.visibility_off)")

    # Fix textfield borders
    content = content.replace(
        "border: OutlineInputBorder(\n                              borderRadius: BorderRadius.circular(12),\n                            ),",
        "border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),\n                            filled: true,\n                            fillColor: colorScheme.surfaceContainerHighest,"
    )

    # Fix filled button shape
    content = content.replace(
        "shape: RoundedRectangleBorder(\n                                borderRadius: BorderRadius.circular(12),\n                              ),",
        "shape: const StadiumBorder(),"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file('lib/features/auth/login_screen.dart')
fix_file('lib/features/auth/register_screen.dart')
