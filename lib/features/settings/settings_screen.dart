import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/widgets/twemoji_text.dart';
import '../../data/services/api_service.dart';
import 'profile_edit_screen.dart';
import '../../core/widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _notificationStatus = 'Memeriksa...';
  bool _isPermissionGranted = false;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;
      
      bool granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
      if (mounted) {
        setState(() {
          _isPermissionGranted = granted;
          if (status == AuthorizationStatus.authorized) {
            _notificationStatus = 'Diizinkan';
          } else if (status == AuthorizationStatus.provisional) {
            _notificationStatus = 'Provisional';
          } else if (status == AuthorizationStatus.denied) {
            _notificationStatus = 'Ditolak / Nonaktif';
          } else {
            _notificationStatus = 'Belum Ditentukan';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationStatus = 'Gagal memeriksa';
          _isPermissionGranted = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = settings.authorizationStatus;
      bool granted = status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
      
      if (mounted) {
        setState(() {
          _isPermissionGranted = granted;
          if (status == AuthorizationStatus.authorized) {
            _notificationStatus = 'Diizinkan';
          } else if (status == AuthorizationStatus.provisional) {
            _notificationStatus = 'Provisional';
          } else {
            _notificationStatus = 'Ditolak / Nonaktif';
          }
        });
      }

      if (granted) {
        final fcmToken = await messaging.getToken();
        if (fcmToken != null && mounted) {
          final apiService = ApiService();
          await apiService.registerFcmToken(fcmToken);
          if (mounted) {
            AppToast.showSuccess(context, message: 'Notifikasi berhasil diaktifkan!');
          }
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Notifikasi Ditolak'),
              content: const Text(
                'Anda telah menonaktifkan notifikasi untuk aplikasi ini. \n\n'
                'Silakan buka Pengaturan HP Anda, lalu masuk ke Aplikasi -> Absensi -> Notifikasi, dan aktifkan izin secara manual.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal meminta izin: $e');
      }
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);
    try {
      final apiService = ApiService();
      final result = await apiService.sendTestNotification();
      if (mounted) {
        AppToast.showSuccess(context, message: result['message'] ?? 'Notifikasi tes berhasil dikirim!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal mengirim notifikasi tes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Info Profil', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        ).then((_) {
                          // refresh profile data when back
                          auth.checkAuthStatus();
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profil'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(user?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user?['email'] ?? '-'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Role: ${user?['role']?['display_name'] ?? '-'}'),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(height: 1),
            ),
            Text('Preferensi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tema'),
              leading: const Icon(Icons.palette),
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: TwemojiText(text: '💻 Sistem')),
                  DropdownMenuItem(value: ThemeMode.light, child: TwemojiText(text: '🌞 Terang')),
                  DropdownMenuItem(value: ThemeMode.dark, child: TwemojiText(text: '🌙 Gelap')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    themeProvider.setThemeMode(val);
                  }
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Izin Notifikasi'),
              subtitle: Text(_notificationStatus),
              leading: Icon(
                _isPermissionGranted ? Icons.notifications_active : Icons.notifications_off,
                color: _isPermissionGranted ? Colors.green : Colors.grey,
              ),
              trailing: OutlinedButton(
                onPressed: _requestNotificationPermission,
                child: Text(_isPermissionGranted ? 'Perbarui' : 'Aktifkan'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kirim Notifikasi Tes'),
              subtitle: const Text('Uji coba kirim notifikasi ke HP Anda'),
              leading: const Icon(Icons.send_to_mobile, color: Colors.blue),
              trailing: ElevatedButton(
                onPressed: _isSendingTest ? null : _sendTestNotification,
                child: _isSendingTest 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Tes Kirim'),
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
