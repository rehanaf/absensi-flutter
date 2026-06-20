import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/twemoji_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = auth.user;


    String getThemeName() {
      if (themeProvider.themeMode == ThemeMode.system) return 'System';
      if (themeProvider.themeMode == ThemeMode.light) return 'Light';
      return 'Dark';
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ShadCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile Info', style: ShadTheme.of(context).textTheme.large),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: ShadTheme.of(context).colorScheme.background,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Edit Profile', style: ShadTheme.of(context).textTheme.h4),
                                      const SizedBox(height: 8),
                                      Text('Perbarui informasi pribadi Anda di bawah ini.', style: ShadTheme.of(context).textTheme.muted),
                                      const SizedBox(height: 24),
                                      const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      ShadInput(initialValue: user?['name']?.toString() ?? ''),
                                      const SizedBox(height: 16),
                                      const Text('Kata Sandi Baru', style: TextStyle(fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 8),
                                      const ShadInput(placeholder: Text('Opsional, biarkan kosong jika tidak diubah'), obscureText: true),
                                      const SizedBox(height: 32),
                                      ShadButton(
                                        child: const Text('Simpan Perubahan'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ShadToaster.of(context).show(
                                            const ShadToast(description: Text('Fitur pembaruan profil sedang dalam pengembangan.')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: ShadTheme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Name: ${user?['name'] ?? '-'}', style: ShadTheme.of(context).textTheme.p),
                  Text('Email: ${user?['email'] ?? '-'}', style: ShadTheme.of(context).textTheme.p),
                  Text('Role: ${user?['role']?['display_name'] ?? '-'}', style: ShadTheme.of(context).textTheme.p),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Preferences', style: ShadTheme.of(context).textTheme.large),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Theme'),
              trailing: SizedBox(
                width: 150,
                child: ShadSelect<ThemeMode>(
                  placeholder: const Text('Pilih Tema'),
                  initialValue: themeProvider.themeMode,
                  options: const [
                    ShadOption(value: ThemeMode.system, child: TwemojiText(text: '💻 System')),
                    ShadOption(value: ThemeMode.light, child: TwemojiText(text: '🌞 Light')),
                    ShadOption(value: ThemeMode.dark, child: TwemojiText(text: '🌙 Dark')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      themeProvider.setThemeMode(val);
                    }
                  },
                  selectedOptionBuilder: (context, value) {
                    if (value == ThemeMode.system) return const TwemojiText(text: '💻 System');
                    if (value == ThemeMode.light) return const TwemojiText(text: '🌞 Light');
                    return const TwemojiText(text: '🌙 Dark');
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            ShadButton.destructive(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.logOut, size: 16),
                  const SizedBox(width: 8),
                  const Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
