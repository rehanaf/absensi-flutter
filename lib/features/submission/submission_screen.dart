import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SubmissionScreen extends StatelessWidget {
  const SubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Fitur Pengajuan (Segera Hadir)',
          style: ShadTheme.of(context).textTheme.muted,
        ),
      ),
    );
  }
}
