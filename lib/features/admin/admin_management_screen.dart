import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'users/admin_users_screen.dart';

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
            
            _buildMenuCard(
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
            
            // Future management items can be added here (e.g. Roles, Departments)
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String description, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
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
