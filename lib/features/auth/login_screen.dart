import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Notify OS to save credentials
      TextInput.finishAutofillContext();
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (settings.getSettingImageUrl('logo') != null && settings.getSettingImageUrl('logo')!.isNotEmpty)
                      Center(
                        child: Image.network(
                          settings.getSettingImageUrl('logo')!, 
                          height: 80, 
                          errorBuilder: (c,e,s) => Column(children: [
                            const Icon(Icons.broken_image, size: 50, color: Colors.red),
                            Text('Error: ', style: const TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center)
                          ])
                        ),
                      ),
                    if (settings.getSettingImageUrl('logo') != null && settings.getSettingImageUrl('logo')!.isNotEmpty)
                      const SizedBox(height: 16),
                    Text(
                      settings.appName,
                      style: ShadTheme.of(context).textTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    if (settings.getSetting('app_description') != null && settings.getSetting('app_description')!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(
                            settings.getSetting('app_description')!,
                            style: ShadTheme.of(context).textTheme.p.copyWith(
                              color: ShadTheme.of(context).colorScheme.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      'Masuk',
                      style: ShadTheme.of(context).textTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
              ShadInput(
                controller: _usernameController,
                placeholder: Text(settings.identityLabel),
                keyboardType: TextInputType.text,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
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
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _login(),
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
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ShadTheme.of(context).colorScheme.primaryForeground))
                    : const Text('Login'),
              ),
              if (settings.allowRegistration) ...[
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text.rich(
                      TextSpan(
                        text: 'Belum punya akun? ',
                        children: [
                          TextSpan(
                            text: 'Daftar sekarang',
                            style: TextStyle(
                              color: ShadTheme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}
