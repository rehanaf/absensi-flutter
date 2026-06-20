import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(authProvider.errorMessage ?? 'Login Failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to',
                style: ShadTheme.of(context).textTheme.h3,
              ),
              Text(
                settings.appName,
                style: ShadTheme.of(context).textTheme.h1,
              ),
              const SizedBox(height: 48),
              ShadInput(
                controller: _usernameController,
                placeholder: Text(settings.identityLabel),
                keyboardType: TextInputType.text,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('👤', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: _passwordController,
                placeholder: const Text('Password'),
                obscureText: _obscurePassword,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('🔒', style: TextStyle(fontSize: 16)),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(_obscurePassword ? '👁️' : '🙈', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
