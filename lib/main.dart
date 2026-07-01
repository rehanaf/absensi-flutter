import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/router.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workspace_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:ui' as ui;

TextStyle _appFont({
  Paint? background,
  Color? backgroundColor,
  Color? color,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  List<ui.FontFeature>? fontFeatures,
  double? fontSize,
  FontStyle? fontStyle,
  FontWeight? fontWeight,
  Paint? foreground,
  double? height,
  double? letterSpacing,
  Locale? locale,
  List<ui.Shadow>? shadows,
  TextBaseline? textBaseline,
  TextStyle? textStyle,
  double? wordSpacing,
}) {
  return TextStyle(
    fontFamily: 'Pliant',
    background: background,
    backgroundColor: backgroundColor,
    color: color,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
    fontFeatures: fontFeatures,
    fontSize: fontSize,
    fontStyle: fontStyle,
    fontWeight: fontWeight,
    foreground: foreground,
    height: height,
    letterSpacing: letterSpacing,
    locale: locale,
    shadows: shadows,
    textBaseline: textBaseline,
    wordSpacing: wordSpacing,
  ).merge(textStyle);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Color _getSeedColor(AppColorPreference pref) {
  switch (pref) {
    case AppColorPreference.blue: return const Color(0xFF4285F4);
    case AppColorPreference.red: return Colors.red;
    case AppColorPreference.green: return Colors.green;
    case AppColorPreference.purple: return Colors.purple;
    default: return const Color(0xFF4285F4); 
  }
}

ShadColorScheme _getShadColorScheme(AppColorPreference pref, bool isDarkMode) {
  switch (pref) {
    case AppColorPreference.blue: return isDarkMode ? const ShadBlueColorScheme.dark() : const ShadBlueColorScheme.light();
    case AppColorPreference.red: return isDarkMode ? const ShadRoseColorScheme.dark() : const ShadRoseColorScheme.light();
    case AppColorPreference.purple: return isDarkMode ? const ShadVioletColorScheme.dark() : const ShadVioletColorScheme.light();
    default: return isDarkMode ? const ShadBlueColorScheme.dark() : const ShadBlueColorScheme.light();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsProvider, ThemeProvider>(
      builder: (context, settings, themeProvider, child) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final pref = themeProvider.colorPreference;
            
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            if (pref == AppColorPreference.dynamic && lightDynamic != null && darkDynamic != null) {
              lightColorScheme = lightDynamic.harmonized();
              darkColorScheme = darkDynamic.harmonized();
            } else if (pref == AppColorPreference.monochrome) {
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: const Color(0xFF4285F4),
                brightness: Brightness.light,
              ).copyWith(primary: Colors.black, onPrimary: Colors.white);
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: const Color(0xFF4285F4),
                brightness: Brightness.dark,
              ).copyWith(primary: Colors.white, onPrimary: Colors.black);
            } else {
              final seed = _getSeedColor(pref);
              lightColorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(primary: Colors.black, onPrimary: Colors.white);
              darkColorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(primary: Colors.white, onPrimary: Colors.black);
            }

            return MaterialApp.router(
              title: settings.appName,
              themeMode: themeProvider.themeMode,
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: lightColorScheme.primary, fontSize: 12, fontFamily: 'Pliant');
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
                  backgroundColor: lightColorScheme.surface,
                ),
              ),
              darkTheme: ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
                fontFamily: 'Pliant',
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: darkColorScheme.primary, fontSize: 12, fontFamily: 'Pliant');
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
                  backgroundColor: darkColorScheme.surface,
                ),
              ),
              routerConfig: router,
              builder: (context, child) {
                return ShadTheme(
                  data: ShadThemeData(
                    brightness: Theme.of(context).brightness,
                    colorScheme: _getShadColorScheme(pref, Theme.of(context).brightness == Brightness.dark),
                    textTheme: ShadTextTheme.fromGoogleFont(_appFont),
                    radius: BorderRadius.circular(12),
                    primaryToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
                    destructiveToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
                  ),
                  child: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
