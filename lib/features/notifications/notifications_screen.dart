import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/widgets/twemoji_text.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TwemojiText(text: '📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: ShadTheme.of(context).textTheme.muted,
          ),
        ],
      ),
    );
  }
}
