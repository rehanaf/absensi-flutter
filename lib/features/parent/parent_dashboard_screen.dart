import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Pemantauan Absensi Anak', style: ShadTheme.of(context).textTheme.muted),
        ),
      ),
    );
  }
}
