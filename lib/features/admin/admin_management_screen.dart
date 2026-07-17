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
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _MenuData({
    required this.title,
    required this.subtitle,
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
    final cs = Theme.of(context).colorScheme;

    final menus = [
      _MenuData(
        title: 'Pengguna',
        subtitle: 'Kelola akun & data user',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF5C6BC0),
        screen: const AdminUsersScreen(),
      ),
      _MenuData(
        title: 'Jadwal Kerja',
        subtitle: 'Atur jam masuk & pulang',
        icon: Icons.access_time_rounded,
        color: const Color(0xFF26A69A),
        screen: const AdminSchedulesScreen(),
      ),
      _MenuData(
        title: 'Kelompok / Kelas',
        subtitle: 'Grup dan kelas pengguna',
        icon: Icons.group_work_rounded,
        color: const Color(0xFFAB47BC),
        screen: const AdminGroupsScreen(),
      ),
      _MenuData(
        title: 'Rekap Absensi',
        subtitle: 'Data kehadiran lengkap',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF66BB6A),
        screen: const AdminAttendancesScreen(),
      ),
      _MenuData(
        title: 'Izin & Cuti',
        subtitle: 'Ajuan izin pengguna',
        icon: Icons.event_available_rounded,
        color: const Color(0xFFFFCA28),
        screen: const AdminPermitsScreen(),
      ),
      _MenuData(
        title: 'Pengumuman',
        subtitle: 'Informasi & notifikasi',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFFF7043),
        screen: const AdminAnnouncementsScreen(),
      ),
      _MenuData(
        title: 'Shift Kerja',
        subtitle: 'Konfigurasi shift & jam',
        icon: Icons.work_history_rounded,
        color: const Color(0xFF26C6DA),
        screen: const AdminShiftsScreen(),
      ),
      _MenuData(
        title: 'Roster Jadwal',
        subtitle: 'Penjadwalan shift harian',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF42A5F5),
        screen: const AdminRostersScreen(),
      ),
      _MenuData(
        title: 'Hari Libur',
        subtitle: 'Tanggal merah & libur',
        icon: Icons.beach_access_rounded,
        color: const Color(0xFFEF5350),
        screen: const AdminHolidaysScreen(),
      ),
      _MenuData(
        title: 'Cabang / Lokasi',
        subtitle: 'Titik absen & area kerja',
        icon: Icons.location_on_rounded,
        color: const Color(0xFFEC407A),
        screen: const AdminLocationsScreen(),
      ),
      _MenuData(
        title: 'Kolom Profil',
        subtitle: 'Form data tambahan user',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFFFFA726),
        screen: const AdminFormFieldsScreen(),
      ),
      _MenuData(
        title: 'Role & Akses',
        subtitle: 'Hak akses pengguna',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF78909C),
        screen: const AdminRolesScreen(),
      ),
      _MenuData(
        title: 'Persetujuan Wali',
        subtitle: 'Permintaan hubungan orang tua',
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF7E57C2),
        screen: const AdminParentChildRequestsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Manajemen',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: isDesktop
                  ? _buildDesktopGrid(context, menus, cs)
                  : _buildMobileList(context, menus, cs),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile: grouped list card menyatu
  Widget _buildMobileList(
      BuildContext context, List<_MenuData> menus, ColorScheme cs) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Render seluruh list dalam satu card
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: cs.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  children: menus.asMap().entries.map((entry) {
                    final i = entry.key;
                    final menu = entry.value;
                    final isLast = i == menus.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => menu.screen),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: menu.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(menu.icon,
                                      color: menu.color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menu.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        menu.subtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 64,
                            color: cs.outlineVariant.withOpacity(0.4),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }
          return null;
        },
        childCount: 1,
      ),
    );
  }

  // Desktop: grid 2 kolom dengan card per item
  Widget _buildDesktopGrid(
      BuildContext context, List<_MenuData> menus, ColorScheme cs) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 68,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final menu = menus[index];
          return Material(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => menu.screen),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.5)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: menu.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(menu.icon, color: menu.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            menu.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            menu.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: menus.length,
      ),
    );
  }
}
