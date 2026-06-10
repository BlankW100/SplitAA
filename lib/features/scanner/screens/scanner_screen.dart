import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../services/ocr_parser.dart';
import 'item_checklist_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();

  String? _imagePath;
  bool _isProcessing = false;

  Future<void> _processImage(String? path) async {
    if (path == null) return;

    setState(() {
      _imagePath = path;
      _isProcessing = true;
    });

    try {
      final recognizedText = await _ocrService.processImage(path);
      final items = OcrParser.parse(recognizedText.text);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemChecklistScreen(
            parsedItems: items,
            imagePath: path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: _imagePath != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Take a photo or pick from gallery\nto scan your receipt.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),

          // Processing indicator
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Reading receipt…'),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            final path = await _cameraService.takePhoto();
                            await _processImage(path);
                          },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            final path = await _cameraService.pickFromGallery();
                            await _processImage(path);
                          },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
