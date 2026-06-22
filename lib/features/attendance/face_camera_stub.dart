import 'package:flutter/material.dart';

class FaceCameraScreen extends StatefulWidget {
  final String title;
  final String? registeredFaceBase64;

  const FaceCameraScreen({super.key, required this.title, this.registeredFaceBase64});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<FaceCameraScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-return null immediately on web so the flow continues smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: const Center(
        child: Text('Kamera pengenalan wajah tidak didukung di versi Web.\nMelanjutkan tanpa verifikasi wajah...'),
      ),
    );
  }
}
