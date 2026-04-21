import 'dart:io';
import 'dart:ui'; // Required for glassmorphism (ImageFilter)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:doculens/models/document_data.dart';
import 'package:doculens/services/ocr_service.dart';
import 'package:doculens/services/telemetry_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final TelemetryService _telemetry = TelemetryService();
  DocumentData _documentData = const DocumentData();
  XFile? _capturedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _telemetry.logScreenView('scanner_screen');
  }

  Future<void> _scanDocument() async {
    if (_isProcessing) return;

    final XFile? pickedImage = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedImage == null) return;

    if (!mounted) return;
    setState(() {
      _capturedImage = pickedImage;
      _isProcessing = true;
    });

    await _telemetry.logOcrStarted();

    try {
      final data = await _ocrService.extractData(pickedImage.path);

      if (!mounted) return;
      setState(() {
        _documentData = data;
        _isProcessing = false;
      });

      await _telemetry.logOcrSuccess(
        namDetected: data.name.isNotEmpty,
        dobDetected: data.dob.isNotEmpty,
        genderDetected: data.gender.isNotEmpty,
      );

      _showCustomSnackBar(
        data.name.isEmpty && data.dob.isEmpty && data.gender.isEmpty
            ? 'No fields detected — try a clearer image'
            : 'Extraction Complete',
        isError: data.name.isEmpty && data.dob.isEmpty && data.gender.isEmpty,
      );
    } catch (e) {
      print('OCR Error: $e');
      await _telemetry.logOcrFailed();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showCustomSnackBar('OCR failed, please try again', isError: true);
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade900.withOpacity(0.9) : Theme.of(context).colorScheme.primary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.red : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required String telemetryFieldName,
    required void Function(String value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
          title: Text('Edit $title', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: title,
              labelStyle: TextStyle(color: theme.colorScheme.primary),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.outline)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                onSave(controller.text.trim());
                _telemetry.logFieldEdited(telemetryFieldName);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Helper to determine badge color and text based on confidence
  (Color, String) _getConfidenceData(double confidence) {
    if (confidence >= 0.7) return (const Color(0xFF10B981), 'High'); // Emerald Green
    if (confidence >= 0.4) return (const Color(0xFFF59E0B), 'Medium'); // Amber
    return (const Color(0xFFEF4444), 'Low'); // Red
  }

  // --- Upgraded Data Cards ---
  Widget _buildFieldCard({
    required String label,
    required String value,
    required double confidence,
    required VoidCallback onEdit,
    required int delayMs, // For staggered animations
  }) {
    final displayValue = value.isEmpty ? 'Waiting for scan...' : value;
    final (badgeColor, badgeText) = _getConfidenceData(confidence);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: value.isNotEmpty ? [
          // Subtle glow if data exists
          BoxShadow(
            color: badgeColor.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: value.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 12),
                Icon(Icons.edit_rounded, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: delayMs.ms).slideX(begin: 0.1, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scan Document', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Top Section: Scanner Viewport ---
                Expanded(
                  flex: 5,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: GestureDetector(
                        onTap: _scanDocument,
                        child: Container(
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            // Neon glowing border
                            border: Border.all(
                              color: _capturedImage == null ? theme.colorScheme.primary.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: _capturedImage == null ? [
                              BoxShadow(color: theme.colorScheme.primary.withOpacity(0.15), blurRadius: 30, spreadRadius: 2, offset: const Offset(0, 10))
                            ] : [],
                          ),
                          child: _capturedImage == null
                              ? _buildEmptyScannerState(theme)
                              : _buildImagePreviewState(theme),
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 32),
                
                // --- Bottom Section: Extracted Data ---
                Text(
                  'Extracted Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 16),

                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildFieldCard(
                          label: 'FULL NAME',
                          value: _documentData.name,
                          confidence: _documentData.nameConfidence,
                          delayMs: 300,
                          onEdit: () => _editField(
                            title: 'Name',
                            initialValue: _documentData.name,
                            telemetryFieldName: 'name',
                            onSave: (value) => setState(() => _documentData = _documentData.copyWith(name: value)),
                          ),
                        ),
                        _buildFieldCard(
                          label: 'DATE OF BIRTH',
                          value: _documentData.dob,
                          confidence: _documentData.dobConfidence,
                          delayMs: 400,
                          onEdit: () => _editField(
                            title: 'Date of Birth',
                            initialValue: _documentData.dob,
                            telemetryFieldName: 'dob',
                            onSave: (value) => setState(() => _documentData = _documentData.copyWith(dob: value)),
                          ),
                        ),
                        _buildFieldCard(
                          label: 'GENDER',
                          value: _documentData.gender,
                          confidence: _documentData.genderConfidence,
                          delayMs: 500,
                          onEdit: () => _editField(
                            title: 'Gender',
                            initialValue: _documentData.gender,
                            telemetryFieldName: 'gender',
                            onSave: (value) => setState(() => _documentData = _documentData.copyWith(gender: value)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Processing Overlay (Glassmorphism) ---
          if (_isProcessing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A cooler loading indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Icon(Icons.document_scanner, color: theme.colorScheme.primary),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Extracting data...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildEmptyScannerState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.center_focus_weak_rounded,
            size: 56,
            color: theme.colorScheme.primary,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
        const SizedBox(height: 24),
        Text(
          'Tap to open camera',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Position ID clearly in frame',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewState(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.cover,
        ),
        // A dark gradient overlay to make the retake button visible
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ElevatedButton.icon(
                onPressed: _scanDocument,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retake', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}