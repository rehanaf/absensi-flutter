import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/twemoji_text.dart';

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
import '../admin/admin_attendances_screen.dart';
import '../admin/admin_settings_screen.dart';

// Parent Mode Screens (Placeholders)
import '../parent/parent_dashboard_screen.dart';

import '../notifications/notifications_screen.dart';

class CustomNavItem {
  final String emoji;
  final String label;
  CustomNavItem(this.emoji, this.label);
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
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<WorkspaceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<AppSettingsProvider>(context);
    final user = auth.user;

    final secondaryColor = ShadTheme.of(context).colorScheme.secondary;

    final List<CustomNavItem> absenItems = [
      CustomNavItem('🏠', 'Beranda'),
      CustomNavItem('🕰️', 'History'),
      CustomNavItem('📝', 'Pengajuan'),
      CustomNavItem('⚙️', 'Setting'),
    ];

    // Tabs for Admin Mode
    final List<Widget> _adminScreens = const [
      AdminDashboardScreen(),
      AdminAttendancesScreen(),
      AdminSettingsScreen(),
      SettingsScreen(), // Reuse generic settings for profile/logout
    ];

    final List<CustomNavItem> adminItems = [
      CustomNavItem('📊', 'Dasbor'),
      CustomNavItem('👥', 'Laporan'),
      CustomNavItem('🛠️', 'Konfigurasi'),
      CustomNavItem('⚙️', 'Setting'),
    ];

    // Tabs for Parent Mode
    final List<Widget> _parentScreens = const [
      ParentDashboardScreen(),
      SettingsScreen(),
    ];

    final List<CustomNavItem> parentItems = [
      CustomNavItem('👶', 'Anak Saya'),
      CustomNavItem('⚙️', 'Setting'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.appName, style: ShadTheme.of(context).textTheme.h4),
        backgroundColor: ShadTheme.of(context).colorScheme.background,
        scrolledUnderElevation: 0,
        actions: [
          if (availableModes.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ShadSelect<String>(
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
                  }
                },
                selectedOptionBuilder: (context, value) {
                  return Text(getModeDisplayName(value));
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_currentIndex == activeItems.length) {
                    _currentIndex = _previousIndex;
                  } else {
                    _previousIndex = _currentIndex;
                    _currentIndex = activeItems.length;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _currentIndex == activeItems.length ? secondaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TwemojiText(text: '🔔', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: activeScreens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ShadTheme.of(context).colorScheme.background,
            border: Border(top: BorderSide(color: ShadTheme.of(context).colorScheme.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(activeItems.length, (index) {
              final item = activeItems[index];
              final isActive = index == _currentIndex;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? secondaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TwemojiText(text: item.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        item.label, 
                        style: TextStyle(
                          fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                          fontWeight: FontWeight.w700, 
                          fontSize: 10,
                          color: isActive 
                            ? ShadTheme.of(context).colorScheme.primary 
                            : ShadTheme.of(context).colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
