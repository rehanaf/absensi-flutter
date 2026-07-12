import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'core/router.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workspace_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
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
  return GoogleFonts.albertSans(
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
    textStyle: textStyle,
    wordSpacing: wordSpacing,
  );
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
            } else {
              Color seedColor;
              switch (pref) {
                case AppColorPreference.blue:
                  seedColor = const Color(0xFF4285F4);
                  break;
                case AppColorPreference.red:
                  seedColor = Colors.red;
                  break;
                case AppColorPreference.green:
                  seedColor = Colors.green;
                  break;
                case AppColorPreference.purple:
                  seedColor = Colors.purple;
                  break;
                case AppColorPreference.monochrome:
                  seedColor = Colors.grey;
                  break;
                default:
                  seedColor = const Color(0xFF4285F4);
              }
              
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              );
            }

            return MaterialApp.router(
              title: settings.appName,
              themeMode: themeProvider.themeMode,
              theme: ThemeData(
                colorScheme: lightColorScheme,
                useMaterial3: true,
                fontFamily: GoogleFonts.albertSans().fontFamily,
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: lightColorScheme.primary, fontSize: 12, fontFamily: GoogleFonts.albertSans().fontFamily);
                    }
                    return TextStyle(color: lightColorScheme.onSurfaceVariant, fontSize: 12, fontFamily: GoogleFonts.albertSans().fontFamily);
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
                fontFamily: GoogleFonts.albertSans().fontFamily,
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return TextStyle(color: darkColorScheme.primary, fontSize: 12, fontFamily: GoogleFonts.albertSans().fontFamily);
                    }
                    return TextStyle(color: darkColorScheme.onSurfaceVariant, fontSize: 12, fontFamily: GoogleFonts.albertSans().fontFamily);
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
                return GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }
}
