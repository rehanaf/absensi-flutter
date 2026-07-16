import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../test/color_test_screen.dart';
import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/twemoji_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/widgets/app_toast.dart';

// Absen Mode Screens
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../submission/submission_screen.dart';
import '../settings/settings_screen.dart';

// Admin Mode Screens (Placeholders)
import '../admin/admin_dashboard_screen.dart';
import '../admin/attendances/admin_attendances_screen.dart';
import '../admin/admin_management_screen.dart';
import '../admin/admin_settings_screen.dart';

// Parent Mode Screens (Placeholders)
import '../parent/parent_dashboard_screen.dart';
import '../parent/parent_history_screen.dart';

import '../notifications/notifications_screen.dart';

class CustomNavItem {
  final IconData icon;
  final String label;
  CustomNavItem(this.icon, this.label);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();
  late final PageController _pageController;
  int _currentIndex = 0;
  int _previousIndex = 0;
  int _unreadNotificationsCount = 0;
  int _lastTotalCount = -1;
  Timer? _notificationTimer;

  Future<void> _fetchUnreadCount({bool triggerAlert = false}) async {
    try {
      final apiService = ApiService();
      final response = await apiService.getNotifications();
      List<dynamic> list = [];
      if (response is Map) {
        if (response.containsKey('data') && response['data'] is List) {
          list = response['data'];
        } else if (response.containsKey('notifications') && response['notifications'] is List) {
          list = response['notifications'];
        }
      } else if (response is List) {
        list = response;
      }
      
      int count = 0;
      for (var item in list) {
        if (item is Map) {
          bool isRead = false;
          if (item.containsKey('is_read')) {
            isRead = item['is_read'] == 1 || item['is_read'] == true;
          } else if (item.containsKey('read_at')) {
            isRead = item['read_at'] != null;
          }
          if (!isRead) count++;
        }
      }
      
      if (mounted) {
        // Tampilkan popup jika ada pengumuman/notifikasi baru masuk di database
        if (triggerAlert && _lastTotalCount != -1 && list.length > _lastTotalCount) {
          final newNotif = list.first;
          final title = newNotif['title'] ?? 'Notifikasi Baru';
          final message = newNotif['message'] ?? newNotif['body'] ?? '';
          
          AppToast.showSuccess(
            context,
            title: title,
            message: message,
            duration: const Duration(seconds: 4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ).then((_) => _fetchUnreadCount(triggerAlert: false));
            },
          );
        }

        setState(() {
          _unreadNotificationsCount = count;
          _lastTotalCount = list.length;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications unread count: $e');
    }
  }

  // Tabs for Absensi Mode
  late final List<Widget> _absenScreens = [
    const HomeScreen(),
    HistoryScreen(key: _historyKey),
    const SubmissionScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchUnreadCount(triggerAlert: false);

    // Polling notifikasi setiap 10 detik agar terupdate secara real-time meskipun tanpa FCM
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchUnreadCount(triggerAlert: true);
    });

    // Auto-select initial mode based on availability after widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
      final availableModes = workspace.getAvailableModes(auth.user);
      
      if (availableModes.isNotEmpty && !availableModes.contains(workspace.activeMode)) {
        // Prefer 'absen' if available, else first available
        workspace.setMode(availableModes.contains('absen') ? 'absen' : availableModes.first);
      }
    });

    // Dengarkan notifikasi saat aplikasi sedang aktif (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _fetchUnreadCount(triggerAlert: true);
    });
  }


  @override
  void dispose() {
    _pageController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final user = auth.user;

    

    final List<CustomNavItem> absenItems = [
      CustomNavItem(Icons.home, 'Beranda'),
      CustomNavItem(Icons.history, 'History'),
      CustomNavItem(Icons.assignment, 'Izin'),
      CustomNavItem(Icons.settings, 'Setting'),
    ];

    // Tabs for Admin Mode
    final List<Widget> _adminScreens = const [
      AdminDashboardScreen(),
      AdminManagementScreen(),
      AdminSettingsScreen(),
      SettingsScreen(), // Reuse generic settings for profile/logout
    ];

    final List<CustomNavItem> adminItems = [
      CustomNavItem(Icons.dashboard, 'Dasbor'),
      CustomNavItem(Icons.folder, 'Manajemen'),
      CustomNavItem(Icons.build, 'Konfigurasi'),
      CustomNavItem(Icons.settings, 'Setting'),
    ];

    // Tabs for Parent Mode
    final List<Widget> _parentScreens = const [
      ParentDashboardScreen(),
      ParentHistoryScreen(),
      SettingsScreen(),
    ];

    final List<CustomNavItem> parentItems = [
      CustomNavItem(Icons.home, 'Anak Saya'),
      CustomNavItem(Icons.history, 'Riwayat'),
      CustomNavItem(Icons.settings, 'Setting'),
    ];

    final String name = user?['name'] ?? 'User';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final availableModes = workspace.getAvailableModes(user);
    
    // Reset index if switching to a mode with fewer tabs
    List<Widget> activeScreens;
    List<CustomNavItem> activeItems;

    switch (workspace.activeMode) {
      case 'admin':
        activeScreens = [..._adminScreens, const NotificationsScreen()];
        activeItems = adminItems;
        break;
      case 'parent':
        activeScreens = [..._parentScreens, const NotificationsScreen()];
        activeItems = parentItems;
        break;
      case 'absen':
      default:
        activeScreens = [..._absenScreens, const NotificationsScreen()];
        activeItems = absenItems;
        break;
    }

    if (_currentIndex >= activeScreens.length) {
      _currentIndex = 0;
    }

    String getModeDisplayName(String mode) {
      switch (mode) {
        case 'admin': return 'Admin';
        case 'parent': return 'Wali/Parent';
        case 'absen': return 'Absen';
        default: return mode;
      }
    }

    String appBarTitle = settings.appName;
    bool isPageTitle = false;

    if (workspace.activeMode == 'absen') {
      if (_currentIndex == 1) { appBarTitle = 'Riwayat Absensi'; isPageTitle = true; }
      if (_currentIndex == 2) { appBarTitle = 'Pengajuan Izin'; isPageTitle = true; }
      if (_currentIndex == 3) { appBarTitle = 'Pengaturan'; isPageTitle = true; }
    } else if (workspace.activeMode == 'admin') {
      if (_currentIndex == 1) { appBarTitle = 'Manajemen'; isPageTitle = true; }
      if (_currentIndex == 2) { appBarTitle = 'Konfigurasi'; isPageTitle = true; }
      if (_currentIndex == 3) { appBarTitle = 'Pengaturan'; isPageTitle = true; }
    } else if (workspace.activeMode == 'parent') {
      if (_currentIndex == 1) { appBarTitle = 'Riwayat Anak'; isPageTitle = true; }
      if (_currentIndex == 2) { appBarTitle = 'Pengaturan'; isPageTitle = true; }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 600;

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          appBarTitle, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: isPageTitle ? FontWeight.normal : FontWeight.bold
          )
        ),
        actions: [
          if (workspace.activeMode == 'absen' && _currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _historyKey.currentState?.fetchHistory();
              },
            ),
          IconButton(
            icon: Badge(
              label: _unreadNotificationsCount > 0 ? Text('$_unreadNotificationsCount') : null,
              isLabelVisible: _unreadNotificationsCount > 0,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ).then((_) => _fetchUnreadCount(triggerAlert: false));
            },
          ),
          Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                child: InkWell(
                  onTap: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: (user?['profile']?['meta_data']?['avatar_base64'] != null && user?['profile']?['meta_data']?['avatar_base64'].toString().isNotEmpty == true)
                        ? MemoryImage(base64Decode(user!['profile']['meta_data']['avatar_base64']))
                        : null,
                    child: (user?['profile']?['meta_data']?['avatar_base64'] == null || user?['profile']?['meta_data']?['avatar_base64'].toString().isEmpty == true)
                        ? Text(
                            initial,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: (user?['profile']?['meta_data']?['avatar_base64'] != null && user?['profile']?['meta_data']?['avatar_base64'].toString().isNotEmpty == true)
                        ? MemoryImage(base64Decode(user!['profile']['meta_data']['avatar_base64']))
                        : null,
                    child: (user?['profile']?['meta_data']?['avatar_base64'] == null || user?['profile']?['meta_data']?['avatar_base64'].toString().isEmpty == true)
                        ? Text(
                            initial,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?['username'] ?? 'username',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant).copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (availableModes.length > 1) ...[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ganti Mode', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: workspace.activeMode,
                      items: availableModes.map((mode) {
                        return DropdownMenuItem<String>(
                          value: mode,
                          child: Text('Mode: ${getModeDisplayName(mode)}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _currentIndex = 0);
                          workspace.setMode(val);
                          Navigator.pop(context); // Close drawer after selection
                        }
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar (Logout)', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            // More menu items could go here
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: activeScreens.map((s) => KeepAliveWrapper(child: s)).toList(),
      ),
      bottomNavigationBar: isDesktop 
          ? null 
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                  setState(() => _currentIndex = index);
                  _pageController.jumpToPage(index);
                },
              destinations: activeItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                );
              }).toList(),
            ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Container(
            width: 80,
            color: Theme.of(context).navigationBarTheme.backgroundColor ?? 
                   Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: activeItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _currentIndex;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        _pageController.jumpToPage(index);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.secondaryContainer 
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onSecondaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(child: scaffold),
        ],
      );
    }

    return scaffold;
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
