import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Semua kolom wajib diisi'),
        ),
      );
      return;
    }

    if (password != passwordConfirm) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Konfirmasi password tidak cocok'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final data = {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
    };

    final success = await authProvider.register(data);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      TextInput.finishAutofillContext();
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Pendaftaran berhasil!'),
        ),
      );
      context.go('/home');
    } else if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(authProvider.errorMessage ?? 'Gagal mendaftar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);

    // If suddenly settings say registration is closed, show warning
    if (!settings.allowRegistration) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Pendaftaran saat ini ditutup.'),
              const SizedBox(height: 16),
              ShadButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      );
    }

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
                      'Daftar',
                      style: ShadTheme.of(context).textTheme.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ShadInput(
                      controller: _nameController,
                      placeholder: const Text('Nama Lengkap'),
                      keyboardType: TextInputType.name,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('📝', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadInput(
                      controller: _usernameController,
                      placeholder: const Text('Username'),
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.newUsername],
                      textInputAction: TextInputAction.next,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('👤', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadInput(
                      controller: _emailController,
                      placeholder: const Text('Email'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('📧', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadInput(
                      controller: _passwordController,
                      placeholder: const Text('Password'),
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: 16),
                    ShadInput(
                      controller: _passwordConfirmController,
                      placeholder: const Text('Konfirmasi Password'),
                      obscureText: _obscurePasswordConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _isLoading ? null : _register(),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('🔐', style: TextStyle(fontSize: 16)),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePasswordConfirm = !_obscurePasswordConfirm;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_obscurePasswordConfirm ? '👁️' : '🙈', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ShadButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ShadTheme.of(context).colorScheme.primaryForeground))
                          : const Text('Daftar'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Text.rich(
                          TextSpan(
                            text: 'Sudah punya akun? ',
                            children: [
                              TextSpan(
                                text: 'Masuk sekarang',
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }
}
