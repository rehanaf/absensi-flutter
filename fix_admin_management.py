with open('lib/features/admin/admin_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write("""import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(16.0),
          children: [
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
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Jadwal Kerja',
                      description: 'Atur jam masuk, jam pulang, dan toleransi keterlambatan',
                      icon: Icons.access_time,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSchedulesScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Kelompok / Kelas',
                      description: 'Kelola pengelompokan pengguna',
                      icon: Icons.category,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminGroupsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Kolom Profil',
                      description: 'Kelola isian tambahan untuk profil pengguna',
                      icon: Icons.edit_note,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFormFieldsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Rekap Absensi',
                      description: 'Kelola dan koreksi data kehadiran secara manual',
                      icon: Icons.fact_check,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAttendancesScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Hari Libur',
                      description: 'Kelola data hari libur nasional atau perusahaan',
                      icon: Icons.event,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminHolidaysScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Shift Kerja',
                      description: 'Kelola data shift kerja karyawan',
                      icon: Icons.work_history,
                      color: Colors.cyan,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminShiftsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Roster Jadwal',
                      description: 'Kelola jadwal / roster per pengguna',
                      icon: Icons.calendar_month,
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRostersScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Pengumuman',
                      description: 'Kelola pengumuman untuk ditampilkan di beranda',
                      icon: Icons.campaign,
                      color: Colors.deepOrange,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAnnouncementsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Izin & Cuti',
                      description: 'Kelola data pengajuan izin dan cuti',
                      icon: Icons.description,
                      color: Colors.amber,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPermitsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Cabang / Lokasi',
                      description: 'Kelola data titik lokasi absensi',
                      icon: Icons.location_on,
                      color: Colors.pink,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLocationsScreen()));
                      },
                    ),
                    Divider(height: 1, color: ShadTheme.of(context).colorScheme.border),
                    _buildMenuRow(
                      context,
                      title: 'Role & Akses',
                      description: 'Kelola peran pengguna dan hak akses',
                      icon: Icons.security,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminRolesScreen()));
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

  Widget _buildMenuRow(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
            Icon(Icons.chevron_right, color: ShadTheme.of(context).colorScheme.muted),
          ],
        ),
      ),
    );
  }
}
""")
