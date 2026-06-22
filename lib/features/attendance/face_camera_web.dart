// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FaceCameraScreen extends StatefulWidget {
  final String title;
  final String? registeredFaceBase64;

  const FaceCameraScreen({
    super.key,
    required this.title,
    this.registeredFaceBase64,
  });

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

class _FaceCameraScreenState extends State<FaceCameraScreen> {
  final String viewType = 'face-video-view';
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _statusMessage = 'Menginisialisasi Kamera...';

  // For capturing
  String? _capturedBase64;

  @override
  void initState() {
    super.initState();
    _initWebCamera();
  }

  Future<void> _initWebCamera() async {
    // Register the video element
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final video = html.VideoElement()
          ..id = 'face-video-web'
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.transform = 'scaleX(-1)'; // Mirror effect
        return video;
      },
    );

    try {
      // Init JS Models
      setState(() => _statusMessage = 'Memuat AI Model...');
      await _callJsAsync('FaceWeb.initModels');

      // Start Camera
      setState(() => _statusMessage = 'Membuka Kamera...');
      await _callJsAsync('FaceWeb.startCamera', ['face-video-web']);
      
      setState(() {
        _isCameraReady = true;
        _statusMessage = widget.registeredFaceBase64 != null 
          ? 'Memproses Wajah...' 
          : 'Posisikan wajah Anda di kamera';
      });

      if (widget.registeredFaceBase64 != null) {
        await _callJsAsync('FaceWeb.prepareRegisteredFace', [widget.registeredFaceBase64]);
        _startAutoVerification();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Gagal memulai kamera: $e';
        });
      }
    }
  }

  // Auto scanning loop for Verification
  Future<void> _startAutoVerification() async {
    if (!mounted || !_isCameraReady || widget.registeredFaceBase64 == null) return;

    if (!_isProcessing) {
      setState(() => _isProcessing = true);
      
      try {
        final resultStr = await _callJsAsync('FaceWeb.captureAndVerify');
        final result = jsonDecode(resultStr);

        if (result['match'] == true) {
          setState(() {
            _capturedBase64 = result['base64'];
            _statusMessage = 'Wajah cocok! Menyimpan absensi...';
          });
          await Future.delayed(const Duration(milliseconds: 1500));
          _saveAndReturn();
          return;
        } else if (result['error'] != null) {
          setState(() => _statusMessage = result['error']);
        }
      } catch (e) {
        setState(() => _statusMessage = 'Error: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }

    // Loop
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted && _capturedBase64 == null) {
      _startAutoVerification();
    }
  }

  // Manual Capture for Registration
  Future<void> _captureForRegistration() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Mendeteksi Wajah...';
    });

    try {
      final resultStr = await _callJsAsync('FaceWeb.captureForRegistration');
      final result = jsonDecode(resultStr);

      if (result['base64'] != null) {
        setState(() {
          _capturedBase64 = result['base64'];
          _statusMessage = 'Wajah berhasil ditangkap';
        });
      } else {
        ShadToaster.of(context).show(ShadToast.destructive(description: Text(result['error'] ?? 'Gagal')));
        setState(() => _statusMessage = result['error'] ?? 'Gagal memindai');
      }
    } catch (e) {
      ShadToaster.of(context).show(ShadToast.destructive(description: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetCamera() {
    setState(() {
      _capturedBase64 = null;
      _statusMessage = 'Posisikan wajah Anda di kamera';
    });
  }

  void _saveAndReturn() {
    if (_capturedBase64 != null) {
      js.context['FaceWeb'].callMethod('stopCamera');
      Navigator.pop(context, {
        'path': _capturedBase64, // Web doesn't use path, we return base64
        'base64': _capturedBase64,
      });
    }
  }

  @override
  void dispose() {
    try {
      js.context['FaceWeb']?.callMethod('stopCamera');
    } catch (_) {}
    super.dispose();
  }

  // Helper to call JS Promises
  Future<dynamic> _callJsAsync(String methodPath, [List<dynamic>? args]) async {
    final parts = methodPath.split('.');
    var obj = js.context[parts[0]];
    if (obj == null) throw Exception('${parts[0]} not found in window');

    final completer = Completer<dynamic>();
    
    // Convert JS Promise to Dart Future
    js.JsObject promise = obj.callMethod(parts[1], args ?? []);
    promise.callMethod('then', [
      (result) => completer.complete(result)
    ]).callMethod('catch', [
      (error) => completer.completeError(error)
    ]);
    
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_capturedBase64 != null)
                    Image.memory(
                      base64Decode(_capturedBase64!),
                      fit: BoxFit.cover,
                    )
                  else
                    HtmlElementView(viewType: viewType),

                  // Overlay text
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (widget.registeredFaceBase64 != null && _isProcessing && _capturedBase64 == null)
                    const Center(child: CircularProgressIndicator(color: Colors.green)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black,
              child: Row(
                children: [
                  if (_capturedBase64 != null) ...[
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: _resetCamera,
                        child: const Text('Scan Ulang', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ShadButton(
                        onPressed: _saveAndReturn,
                        child: const Text('Simpan', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ] else if (widget.registeredFaceBase64 == null) ...[
                    // Registration Mode: Need manual capture button
                    Expanded(
                      child: ShadButton(
                        onPressed: _isCameraReady && !_isProcessing ? _captureForRegistration : null,
                        child: _isProcessing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Ambil Foto', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
