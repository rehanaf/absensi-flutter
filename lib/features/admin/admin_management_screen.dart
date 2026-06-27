import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text('Manajemen', style: ShadTheme.of(context).textTheme.h3),
            const SizedBox(height: 8),
            Text('Kelola data master sistem', style: ShadTheme.of(context).textTheme.muted),
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ShadTheme.of(context).colorScheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildMenuRow(
                      context,
                      title: 'Pengguna',
                      description: 'Kelola data karyawan, siswa, dan admin',
                      icon: LucideIcons.users,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Jadwal Kerja',
                      description: 'Atur jam masuk, jam pulang, dan toleransi keterlambatan',
                      icon: LucideIcons.calendarClock,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminSchedulesScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Kelompok / Kelas',
                      description: 'Kelola pengelompokan pengguna',
                      icon: LucideIcons.layoutGrid,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminGroupsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Kolom Profil',
                      description: 'Kelola isian tambahan untuk profil pengguna',
                      icon: LucideIcons.formInput,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminFormFieldsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Rekap Absensi',
                      description: 'Kelola dan koreksi data kehadiran secara manual',
                      icon: LucideIcons.clipboardList,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminAttendancesScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Hari Libur',
                      description: 'Kelola data hari libur nasional atau perusahaan',
                      icon: LucideIcons.calendar,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminHolidaysScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Shift Kerja',
                      description: 'Kelola data shift kerja karyawan',
                      icon: LucideIcons.clock,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminShiftsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Roster Jadwal',
                      description: 'Kelola jadwal / roster per pengguna',
                      icon: LucideIcons.calendarDays,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminRostersScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Pengumuman',
                      description: 'Kelola pengumuman untuk ditampilkan di beranda',
                      icon: LucideIcons.megaphone,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminAnnouncementsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Izin & Cuti',
                      description: 'Kelola data pengajuan izin dan cuti',
                      icon: LucideIcons.fileText,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminPermitsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Cabang / Lokasi',
                      description: 'Kelola data titik lokasi absensi',
                      icon: LucideIcons.mapPin,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminLocationsScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Role & Akses',
                      description: 'Kelola peran pengguna dan hak akses',
                      icon: LucideIcons.shieldCheck,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminRolesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, {required String title, required String description, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ShadTheme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ShadTheme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ShadTheme.of(context).textTheme.large),
                  const SizedBox(height: 4),
                  Text(description, style: ShadTheme.of(context).textTheme.muted),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: ShadTheme.of(context).colorScheme.muted),
          ],
        ),
      ),
    );
  }
}
