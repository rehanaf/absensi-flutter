import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../data/services/face_recognition_service.dart';

enum CameraState { initializing, loadingRegisteredFace, scanning, capturing, captured, verifying, mismatch }

class FaceCameraScreen extends StatefulWidget {
  final String title;
  final String? registeredFaceBase64; // Passed when checking in

  const FaceCameraScreen({super.key, required this.title, this.registeredFaceBase64});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
}

// Function to compress image in a separate isolate
Uint8List _compressImage(Uint8List list) {
  img.Image? image = img.decodeImage(list);
  if (image == null) return list;
  
  // Flip horizontally so the backend receives the mirrored version
  image = img.flipHorizontal(image);
  
  if (image.width > 400) {
    image = img.copyResize(image, width: 400);
  }
  
  return Uint8List.fromList(img.encodeJpg(image, quality: 60));
}

class _FaceCameraScreenState extends State<FaceCameraScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isDetecting = false;
  CameraState _cameraState = CameraState.initializing;
  String? _capturedImagePath;
  String? _capturedBase64;
  double _faceAccuracy = 0.0;
  
  List<double>? _registeredEmbedding;
  String _statusMessage = 'Memuat Kamera...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await FaceRecognitionService().initialize();
    
    if (widget.registeredFaceBase64 != null) {
      setState(() {
        _cameraState = CameraState.loadingRegisteredFace;
        _statusMessage = 'Memuat Data Wajah Terdaftar...';
      });
      await _loadRegisteredFace();
    }
    
    await _initCamera();
  }

  Future<void> _loadRegisteredFace() async {
    try {
      final bytes = base64Decode(widget.registeredFaceBase64!);
      
      // Save temp file for ML Kit
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_registered.jpg');
      await tempFile.writeAsBytes(bytes);
      
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        throw Exception("Wajah terdaftar tidak terdeteksi oleh ML Kit");
      }
      
      final face = faces.first;
      final rect = face.boundingBox;
      
      // Decode with image package to crop
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception("Gagal decode gambar terdaftar");
      
      // Pad crop rectangle a bit
      int x = max(0, rect.left.toInt() - 20);
      int y = max(0, rect.top.toInt() - 20);
      int w = min(originalImage.width - x, rect.width.toInt() + 40);
      int h = min(originalImage.height - y, rect.height.toInt() + 40);
      
      img.Image croppedFace = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
      
      _registeredEmbedding = await FaceRecognitionService().extractEmbedding(croppedFace);
    } catch (e) {
      print('Load Registered Face Error: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal memuat wajah terdaftar. Hubungi Admin.')),
        );
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _cameraState = CameraState.scanning;
      });

      _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting || (_cameraState != CameraState.scanning && _cameraState != CameraState.mismatch)) return;
        _isDetecting = true;
        _processCameraImage(image, frontCamera);
      });
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal inisialisasi kamera: $e')),
        );
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image, CameraDescription camera) async {
    if (_cameraState != CameraState.scanning && _cameraState != CameraState.mismatch) {
      _isDetecting = false;
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted && (_cameraState == CameraState.scanning || _cameraState == CameraState.mismatch)) {
        if (faces.isNotEmpty) {
          final face = faces.first;
          
          final rotY = face.headEulerAngleY ?? 0;
          final rotZ = face.headEulerAngleZ ?? 0;
          double deviation = rotY.abs() + rotZ.abs();
          double accuracy = 100 - deviation;
          if (accuracy < 0) accuracy = 0;
          if (accuracy > 99.9) accuracy = 99.9;

          if (accuracy > 75) {
            _autoCaptureAndVerify(accuracy, face.boundingBox);
          }
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _autoCaptureAndVerify(double accuracy, Rect faceBounds) async {
    if (_cameraState != CameraState.scanning && _cameraState != CameraState.mismatch) return;

    setState(() {
      _cameraState = CameraState.capturing;
      _faceAccuracy = accuracy;
    });

    try {
      await _cameraController!.stopImageStream();
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();
      
      if (widget.registeredFaceBase64 != null && _registeredEmbedding != null) {
        setState(() {
          _cameraState = CameraState.verifying;
          _statusMessage = 'Memverifikasi Wajah...';
        });

        img.Image? liveImage = img.decodeImage(bytes);
        if (liveImage != null) {
          // Adjust bounds for aspect ratio difference if needed, but roughly:
          double scaleX = liveImage.width / _cameraController!.value.previewSize!.height;
          double scaleY = liveImage.height / _cameraController!.value.previewSize!.width;
          
          int x = max(0, (faceBounds.left * scaleX).toInt() - 20);
          int y = max(0, (faceBounds.top * scaleY).toInt() - 20);
          int w = min(liveImage.width - x, (faceBounds.width * scaleX).toInt() + 40);
          int h = min(liveImage.height - y, (faceBounds.height * scaleY).toInt() + 40);

          img.Image croppedLive = img.copyCrop(liveImage, x: x, y: y, width: w, height: h);
          List<double> liveEmbedding = await FaceRecognitionService().extractEmbedding(croppedLive);
          
          double distance = FaceRecognitionService().calculateDistance(liveEmbedding, _registeredEmbedding!);
          
          if (distance > 1.0) {
            // Mismatch!
            setState(() {
              _cameraState = CameraState.mismatch;
              _statusMessage = 'Wajah Tidak Cocok! (Dist: ${distance.toStringAsFixed(2)})';
            });
            // Restart stream after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _cameraState == CameraState.mismatch) {
                _initCamera();
              }
            });
            return;
          }
        }
      }

      // If we reach here, either it's Registration (no registered face to check), or Verification passed
      final compressedBytes = await compute(_compressImage, bytes);
      final base64String = base64Encode(compressedBytes);

      if (mounted) {
        setState(() {
          _capturedImagePath = imageFile.path;
          _capturedBase64 = base64String;
          _cameraState = CameraState.captured;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraState = CameraState.scanning;
        });
        _initCamera();
      }
    }
  }

  void _resetCamera() {
    setState(() {
      _cameraState = CameraState.scanning;
      _capturedImagePath = null;
      _capturedBase64 = null;
      _faceAccuracy = 0.0;
    });
    _initCamera();
  }

  void _saveAndReturn() {
    if (_capturedBase64 != null && _capturedImagePath != null) {
      Navigator.pop(context, {
        'base64': _capturedBase64,
        'path': _capturedImagePath,
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCameraReady = _cameraController != null && _cameraController!.value.isInitialized;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_cameraState == CameraState.captured && _capturedImagePath != null)
                    Transform.scale(
                      scaleX: -1,
                      child: Image.file(File(_capturedImagePath!), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    )
                  else if (isCameraReady && (_cameraState == CameraState.scanning || _cameraState == CameraState.capturing || _cameraState == CameraState.verifying || _cameraState == CameraState.mismatch))
                    CameraPreview(_cameraController!)
                  else
                    const Center(child: CircularProgressIndicator()),

                  if (_cameraState == CameraState.scanning || _cameraState == CameraState.mismatch)
                    Container(
                      width: 250,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _cameraState == CameraState.mismatch ? Colors.red : Colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(150),
                      ),
                    ),

                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _cameraState == CameraState.captured 
                            ? Colors.green.withValues(alpha: 0.9) 
                            : _cameraState == CameraState.mismatch
                                ? Colors.red.withValues(alpha: 0.9)
                                : _cameraState == CameraState.capturing || _cameraState == CameraState.verifying 
                                    ? Colors.orange.withValues(alpha: 0.9)
                                    : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _cameraState == CameraState.captured
                            ? (widget.registeredFaceBase64 != null ? 'Wajah Cocok! Akurasi: ${_faceAccuracy.toStringAsFixed(1)}%' : 'Akurasi Wajah: ${_faceAccuracy.toStringAsFixed(1)}%')
                            : _cameraState == CameraState.mismatch
                                ? _statusMessage
                                : _cameraState == CameraState.verifying
                                    ? _statusMessage
                                    : _cameraState == CameraState.capturing
                                        ? 'Menangkap Gambar...'
                                        : _cameraState == CameraState.initializing || _cameraState == CameraState.loadingRegisteredFace
                                            ? _statusMessage
                                            : 'Posisikan wajah Anda lurus ke kamera',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black,
              child: Row(
                children: [
                  if (_cameraState == CameraState.captured) ...[
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
                  ] else ...[
                    Expanded(
                      child: ShadButton(
                        onPressed: null,
                        child: (_cameraState == CameraState.capturing || _cameraState == CameraState.verifying || _cameraState == CameraState.loadingRegisteredFace)
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Mendeteksi Wajah...', style: TextStyle(color: Colors.white54)),
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
