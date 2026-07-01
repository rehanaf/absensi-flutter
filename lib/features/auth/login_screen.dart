import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  final _formKey = GlobalKey<FormState>();
  String? _apiError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() {
      _apiError = null;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      setState(() {
        _apiError = authProvider.errorMessage ?? 'Login Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (settings.getSettingImageUrl('logo') != null && settings.getSettingImageUrl('logo')!.isNotEmpty)
                          Center(
                            child: Image.network(
                              settings.getSettingImageUrl('logo')!, 
                              height: 80, 
                              errorBuilder: (c,e,s) => const Column(children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.red),
                                Text('Error: ', style: TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center)
                              ])
                            ),
                          ),
                        if (settings.getSettingImageUrl('logo') != null && settings.getSettingImageUrl('logo')!.isNotEmpty)
                          const SizedBox(height: 16),
                        Text(
                          settings.appName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (settings.getSetting('app_description') != null && settings.getSetting('app_description')!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                settings.getSetting('app_description')!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Text(
                          'Masuk',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _usernameController,
                          validator: (value) => (value == null || value.trim().isEmpty) ? '${settings.identityLabel} tidak boleh kosong' : null,
                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },
                          keyboardType: TextInputType.text,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: settings.identityLabel,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.person),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 2)),
                            filled: true,
                            fillColor: colorScheme.onSurface.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Password tidak boleh kosong' : null,
                          onChanged: (_) { if (_apiError != null) setState(() => _apiError = null); },
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _isLoading ? null : _login(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            errorText: _apiError,
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.lock),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: colorScheme.onSurfaceVariant),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.error, width: 2)),
                            filled: true,
                            fillColor: colorScheme.onSurface.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            child: _isLoading 
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                                : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        if (settings.allowRegistration) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Belum punya akun? ',
                                  style: textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: 'Daftar sekarang',
                                      style: TextStyle(
                                        color: colorScheme.primary,
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
