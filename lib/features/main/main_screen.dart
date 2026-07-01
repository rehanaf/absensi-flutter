import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../test/color_test_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/twemoji_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../providers/auth_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/workspace_provider.dart';

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
  int _currentIndex = 0;
  int _previousIndex = 0;

  // Tabs for Absensi Mode
  final List<Widget> _absenScreens = const [
    HomeScreen(),
    HistoryScreen(),
    SubmissionScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
      if (mounted && message.notification != null) {
        ShadToaster.of(context).show(
          ShadToast(
            title: Text(message.notification!.title ?? 'Notifikasi Baru'),
            description: Text(message.notification!.body ?? ''),
            action: ShadButton.outline(
              child: const Text('Lihat'),
              onPressed: () {
                ShadToaster.of(context).hide();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final user = auth.user;

    final secondaryColor = ShadTheme.of(context).colorScheme.secondary;

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
      SettingsScreen(),
    ];

    final List<CustomNavItem> parentItems = [
      CustomNavItem(Icons.child_care, 'Anak Saya'),
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 600;

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          settings.appName, 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
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
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: ShadTheme.of(context).colorScheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: ShadTheme.of(context).colorScheme.primary.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: ShadTheme.of(context).colorScheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ShadTheme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: ShadTheme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?['username'] ?? 'username',
                    style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 14),
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
                    Text('Ganti Mode', style: ShadTheme.of(context).textTheme.large),
                    const SizedBox(height: 12),
                    ShadSelect<String>(
                      placeholder: Text('Mode: ${getModeDisplayName(workspace.activeMode)}'),
                      initialValue: workspace.activeMode,
                      options: availableModes.map((mode) {
                        return ShadOption(
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
                      selectedOptionBuilder: (context, value) {
                        return Text(getModeDisplayName(value));
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
            ],
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Test Warna Material 3'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ColorTestScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar (Logout)', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
            // More menu items could go here
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: activeScreens,
      ),
      bottomNavigationBar: isDesktop 
          ? null 
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
                      onTap: () => setState(() => _currentIndex = index),
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
