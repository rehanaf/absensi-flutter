import re

def fix_main(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix the monochrome ColorScheme definition
    old_mono = """            } else if (pref == AppColorPreference.monochrome) {
              lightColorScheme = const ColorScheme.light(
                primary: Colors.black,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              );
              darkColorScheme = const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                surface: Color(0xFF121212),
                onSurface: Colors.white,
              );
            }"""
            
    new_mono = """            } else if (pref == AppColorPreference.monochrome) {
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: const Color(0xFF64748B), // Neutral Slate/Zinc
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: const Color(0xFF64748B),
                brightness: Brightness.dark,
              );
            }"""
            
    content = content.replace(old_mono, new_mono)

    # 2. Add NavigationBarTheme to ThemeData
    # Find ThemeData(
    #   colorScheme: lightColorScheme,
    #   useMaterial3: true,
    #   fontFamily: 'Pliant',
    # )
    
    old_theme_light = """              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
              ),"""
              
    new_theme_light = """              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: lightColorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pliant');
                    }
                    return TextStyle(color: lightColorScheme.onSurfaceVariant, fontSize: 12, fontFamily: 'Pliant');
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return IconThemeData(color: lightColorScheme.onSecondaryContainer);
                    }
                    return IconThemeData(color: lightColorScheme.onSurfaceVariant);
                  }),
                  indicatorColor: lightColorScheme.secondaryContainer,
                ),
              ),"""
              
    content = content.replace(old_theme_light, new_theme_light)

    old_theme_dark = """              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
              ),"""
              
    new_theme_dark = """              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: darkColorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pliant');
                    }
                    return TextStyle(color: darkColorScheme.onSurfaceVariant, fontSize: 12, fontFamily: 'Pliant');
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return IconThemeData(color: darkColorScheme.onSecondaryContainer);
                    }
                    return IconThemeData(color: darkColorScheme.onSurfaceVariant);
                  }),
                  indicatorColor: darkColorScheme.secondaryContainer,
                ),
              ),"""
              
    content = content.replace(old_theme_dark, new_theme_dark)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

try:
    fix_main('lib/main.dart')
except Exception as e:
    print(f"Error: {e}")
