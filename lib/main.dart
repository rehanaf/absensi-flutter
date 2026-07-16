import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dynamic_color/dynamic_color.dart';
import 'core/router.dart';
import 'core/api_client.dart';
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
  return GoogleFonts.quicksand(
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

  // Setup global unauthorized redirect
  ApiClient.onUnauthorized = () {
    router.go('/login');
  };

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
        const lightColorScheme = ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF1D4ED8), // Royal Blue (high contrast)
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFDBEAFE),
          onPrimaryContainer: Color(0xFF1E40AF),
          secondary: Color(0xFF0284C7),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE0F2FE),
          onSecondaryContainer: Color(0xFF0369A1),
          tertiary: Color(0xFF0D9488),
          onTertiary: Colors.white,
          error: Color(0xFFDC2626),
          onError: Colors.white,
          surface: Color(0xFFF8FAFC),
          onSurface: Color(0xFF0F172A),
          surfaceContainerHighest: Color(0xFFF1F5F9),
          onSurfaceVariant: Color(0xFF475569),
          outline: Color(0xFFCBD5E1),
          shadow: Colors.black,
        );

        const darkColorScheme = ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3B82F6), // Vibrant Blue
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF1E3A8A),
          onPrimaryContainer: Color(0xFF93C5FD),
          secondary: Color(0xFF38BDF8),
          onSecondary: Color(0xFF0F172A),
          secondaryContainer: Color(0xFF0369A1),
          onSecondaryContainer: Color(0xFFBAE6FD),
          tertiary: Color(0xFF2DD4BF),
          onTertiary: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
          onError: Colors.white,
          surface: Color(0xFF0F172A), // Dark slate
          onSurface: Color(0xFFF8FAFC),
          surfaceContainerHighest: Color(0xFF1E293B),
          onSurfaceVariant: Color(0xFF94A3B8),
          outline: Color(0xFF475569),
          shadow: Colors.black,
        );

        return MaterialApp.router(
          title: settings.appName,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            fontFamily: GoogleFonts.quicksand().fontFamily,
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: lightColorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.quicksand().fontFamily);
                }
                return TextStyle(color: lightColorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.quicksand().fontFamily);
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
            fontFamily: GoogleFonts.quicksand().fontFamily,
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: darkColorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.quicksand().fontFamily);
                }
                return TextStyle(color: darkColorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.quicksand().fontFamily);
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
  }
}
