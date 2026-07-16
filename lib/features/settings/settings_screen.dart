import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  void _showPresetOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Warna Kartu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildPresetItem('blue', 'Biru Klasik', [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]),
                      _buildPresetItem('orange', 'Orange Senja', [const Color(0xFFF59E0B), const Color(0xFFD97706)]),
                      _buildPresetItem('green', 'Teal Rimbun', [const Color(0xFF10B981), const Color(0xFF047857)]),
                      _buildPresetItem('purple', 'Ungu Midnight', [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]),
                      _buildPresetItem('rose', 'Merah Mawar', [const Color(0xFFF43F5E), const Color(0xFFBE185D)]),
                      _buildPresetItem('slate', 'Abu Elegan', [const Color(0xFF64748B), const Color(0xFF334155)]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetItem(String presetKey, String name, List<Color> colors) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updateCardPreset(presetKey);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCardPreset(String presetKey) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile({'card_preset': presetKey});
      if (mounted) {
        AppToast.showSuccess(context, message: 'Warna kartu berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal memperbarui warna kartu: $e');
      }
    }
  }


  void _showImagePickerOptions({required String? currentImage}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (currentImage != null && currentImage.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfileImage(base64Str: "");
                  },
                ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        _updateProfileImage(base64Str: base64Str);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal mengambil gambar: $e');
      }
    }
  }

  Future<void> _updateProfileImage({required String base64Str}) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfile({'avatar_base64': base64Str});
      if (mounted) {
        AppToast.showSuccess(
          context, 
          message: base64Str.isEmpty ? 'Foto profil berhasil dihapus!' : 'Foto profil berhasil diperbarui!'
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, message: 'Gagal memperbarui profil: $e');
      }
    }
  }

  Widget _buildProfileCard(Map<String, dynamic>? user) {
    final String name = user?['name'] ?? 'User';
    final String username = user?['username'] ?? '-';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = user?['profile'];
    final metaData = profile?['meta_data'];
    final String? avatarBase64 = metaData?['avatar_base64'];
    final String? cardPreset = metaData?['card_preset'];

    // Map presets to gradients
    final cardPresets = {
      'blue': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      'orange': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'green': [const Color(0xFF10B981), const Color(0xFF047857)],
      'purple': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      'rose': [const Color(0xFFF43F5E), const Color(0xFFBE185D)],
      'slate': [const Color(0xFF64748B), const Color(0xFF334155)],
    };

    List<Color> gradientColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary.withRed(100).withBlue(200),
    ];

    if (cardPreset != null && cardPresets.containsKey(cardPreset)) {
      gradientColors = cardPresets[cardPreset]!;
    } else if (isDark) {
      gradientColors = [
        Theme.of(context).colorScheme.surfaceContainerHigh,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ];
    }

    final bool isCardColored = !isDark || (cardPreset != null && cardPreset != 'default' && cardPreset != 'slate');

    final boxDec = BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withOpacity(isDark ? 0.05 : 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: boxDec,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -32,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              icon: Icon(
                Icons.palette,
                color: isCardColored ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: _showPresetOptions,
              tooltip: 'Pilih Warna Kartu',
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePickerOptions(currentImage: avatarBase64),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: (avatarBase64 != null && avatarBase64.isNotEmpty)
                              ? MemoryImage(base64Decode(avatarBase64))
                              : null,
                          child: (avatarBase64 == null || avatarBase64.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isCardColored ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        username,
                        style: TextStyle(
                          color: isCardColored ? Colors.white.withOpacity(0.85) : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                          auth.checkAuthStatus();
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profil'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileCard(user),
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
