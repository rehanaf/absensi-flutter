import 'package:flutter/material.dart';
import 'users/admin_users_screen.dart';
import 'schedules/admin_schedules_screen.dart';
import 'groups/admin_groups_screen.dart';
import 'form_fields/admin_form_fields_screen.dart';
import 'attendances/admin_attendances_screen.dart';
import 'holidays/admin_holidays_screen.dart';
import 'shifts/admin_shifts_screen.dart';
import 'rosters/admin_rosters_screen.dart';
import 'announcements/admin_announcements_screen.dart';
import 'permits/admin_permits_screen.dart';
import 'locations/admin_locations_screen.dart';
import 'roles/admin_roles_screen.dart';
import 'parent_child_requests/admin_parent_child_requests_screen.dart';

class _MenuData {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _MenuData({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    final menus = [
      const _MenuData(
        title: 'Pengguna',
        icon: Icons.people,
        color: Colors.blue,
        screen: AdminUsersScreen(),
      ),
      const _MenuData(
        title: 'Jadwal Kerja',
        icon: Icons.access_time,
        color: Colors.teal,
        screen: AdminSchedulesScreen(),
      ),
      const _MenuData(
        title: 'Kelompok / Kelas',
        icon: Icons.category,
        color: Colors.purple,
        screen: AdminGroupsScreen(),
      ),
      const _MenuData(
        title: 'Kolom Profil',
        icon: Icons.edit_note,
        color: Colors.orange,
        screen: AdminFormFieldsScreen(),
      ),
      const _MenuData(
        title: 'Rekap Absensi',
        icon: Icons.fact_check,
        color: Colors.green,
        screen: AdminAttendancesScreen(),
      ),
      const _MenuData(
        title: 'Hari Libur',
        icon: Icons.event,
        color: Colors.redAccent,
        screen: AdminHolidaysScreen(),
      ),
      const _MenuData(
        title: 'Shift Kerja',
        icon: Icons.work_history,
        color: Colors.cyan,
        screen: AdminShiftsScreen(),
      ),
      const _MenuData(
        title: 'Roster Jadwal',
        icon: Icons.calendar_month,
        color: Colors.indigo,
        screen: AdminRostersScreen(),
      ),
      const _MenuData(
        title: 'Pengumuman',
        icon: Icons.campaign,
        color: Colors.deepOrange,
        screen: AdminAnnouncementsScreen(),
      ),
      const _MenuData(
        title: 'Izin & Cuti',
        icon: Icons.description,
        color: Colors.amber,
        screen: AdminPermitsScreen(),
      ),
      const _MenuData(
        title: 'Cabang / Lokasi',
        icon: Icons.location_on,
        color: Colors.pink,
        screen: AdminLocationsScreen(),
      ),
      const _MenuData(
        title: 'Role & Akses',
        icon: Icons.security,
        color: Colors.blueGrey,
        screen: AdminRolesScreen(),
      ),
      const _MenuData(
        title: 'Persetujuan Wali Murid',
        icon: Icons.family_restroom,
        color: Colors.indigoAccent,
        screen: AdminParentChildRequestsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            mainAxisExtent: 56,
          ),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => menu.screen),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: menu.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(menu.icon, color: menu.color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        menu.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
