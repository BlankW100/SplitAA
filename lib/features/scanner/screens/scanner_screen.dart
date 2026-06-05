import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();
  
  String? _imagePath;
  String _recognizedTextStr = '';
  bool _isProcessing = false;

  Future<void> _processImage(String? path) async {
    if (path == null) return;

    setState(() {
      _imagePath = path;
      _isProcessing = true;
      _recognizedTextStr = '';
    });

    try {
      final recognizedText = await _ocrService.processImage(path);
      setState(() {
        _recognizedTextStr = recognizedText.text;
      });
      // TODO: Pass to parser algorithm
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_imagePath != null) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(_imagePath!),
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ] else ...[
              const SizedBox(height: 100),
              const Center(child: Text('No image selected.')),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final path = await _cameraService.takePhoto();
                    await _processImage(path);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final path = await _cameraService.pickFromGallery();
                    await _processImage(path);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const CircularProgressIndicator()
            else if (_recognizedTextStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_recognizedTextStr),
              ),
          ],
        ),
      ),
    );
  }
}
