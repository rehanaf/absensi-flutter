import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      _isInitialized = true;
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  /// Extract a 192-dimensional embedding vector from a cropped face image
  Future<List<double>> extractEmbedding(img.Image faceImage) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }
    
    if (_interpreter == null) throw Exception("Interpreter not loaded");

    // Resize image to exactly 112x112 as expected by MobileFaceNet
    img.Image resized = img.copyResize(faceImage, width: 112, height: 112);

    // Prepare input tensor [1, 112, 112, 3] of float32
    var input = List.generate(
      1,
      (i) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) => List.filled(3, 0.0),
        ),
      ),
    );

    // Normalize pixel values to [-1.0, 1.0]
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        // MobileFaceNet normalization: (val - 127.5) / 128.0
        input[0][y][x][0] = (pixel.r - 127.5) / 128.0;
        input[0][y][x][1] = (pixel.g - 127.5) / 128.0;
        input[0][y][x][2] = (pixel.b - 127.5) / 128.0;
      }
    }

    // Output tensor [1, 192] of float32
    var output = List.generate(1, (i) => List.filled(192, 0.0));

    // Run inference
    _interpreter!.run(input, output);

    List<double> raw = output[0];
    
    // L2 Normalization (Crucial for Euclidean Distance / Cosine Similarity)
    double sumSq = 0.0;
    for (double v in raw) {
      sumSq += v * v;
    }
    double magnitude = sqrt(sumSq);
    if (magnitude == 0) magnitude = 1e-10; // Prevent division by zero
    
    List<double> normalized = raw.map((v) => v / magnitude).toList();

    // Return the normalized 192D vector
    return normalized;
  }

  /// Calculate Euclidean distance between two 192D embeddings
  double calculateDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 999.0;
    
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      final diff = e1[i] - e2[i];
      sum += diff * diff;
    }
    
    return sqrt(sum);
  }
}
