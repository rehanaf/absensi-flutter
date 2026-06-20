import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AdminAttendancesScreen extends StatelessWidget {
  const AdminAttendancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Laporan Seluruh Absensi', style: ShadTheme.of(context).textTheme.muted),
        ),
      ),
    );
  }
}
