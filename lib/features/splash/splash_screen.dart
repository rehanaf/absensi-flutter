import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isError = false;
      _errorMsg = null;
    });

    // Get providers before async
    final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Fetch settings first
    await settingsProvider.fetchSettings();

    if (settingsProvider.errorMessage != null) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMsg = settingsProvider.errorMessage;
        });
      }
      return;
    }

    // Then check auth status
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat pengaturan aplikasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMsg ?? 'Tidak dapat terhubung ke server.',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
