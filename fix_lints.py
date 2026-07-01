import os

with open('lib/features/home/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('.withOpacity(', '.withValues(alpha: ')
content = content.replace("import 'dart:convert';\n", "")
content = content.replace("import 'package:flutter/foundation.dart' show kIsWeb;\n", "")
content = content.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
content = content.replace("import 'package:intl/intl.dart';\n", "")

with open('lib/features/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
