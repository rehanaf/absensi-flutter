import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FaceCameraScreen extends StatefulWidget {
  final String title;

  const FaceCameraScreen({super.key, required this.title});

  @override
  State<FaceCameraScreen> createState() => _FaceCameraScreenState();
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

  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _faceDetected = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Use medium resolution to keep image size small and prevent 500 errors on upload
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting || _isProcessingImage) return;
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

      if (mounted) {
        setState(() {
          _faceDetected = faces.isNotEmpty;
        });
      }
    } catch (e) {
      // Ignore processing errors
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _takePictureAndReturn() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessingImage) return;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      await _cameraController!.stopImageStream();
      final XFile image = await _cameraController!.takePicture();
      
      // Convert to base64
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      if (mounted) {
        Navigator.pop(context, {
          'base64': base64String,
          'path': image.path,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Gagal mengambil foto: $e')),
        );
        _initCamera(); // Restart stream
      }
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
                  if (_isCameraInitialized)
                    CameraPreview(_cameraController!)
                  else
                    const Center(child: CircularProgressIndicator()),

                  // Face outline guide
                  Container(
                    width: 250,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _faceDetected ? Colors.green : Colors.white.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(150), // Oval shape
                    ),
                  ),

                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _faceDetected ? Colors.green.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _faceDetected ? 'Wajah Terdeteksi!' : 'Posisikan wajah Anda di dalam area',
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
              child: ShadButton(
                onPressed: (_faceDetected && !_isProcessingImage) ? _takePictureAndReturn : null,
                size: ShadButtonSize.lg,
                child: _isProcessingImage
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan / Lanjutkan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
