import 'dart:io';
import 'dart:ui'; // Required for glassmorphism (ImageFilter)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:doculens/models/document_data.dart';
import 'package:doculens/services/ocr_service.dart';
import 'package:doculens/services/telemetry_service.dart';
import 'package:doculens/theme/app_theme.dart';
import 'package:doculens/services/database_service.dart';
import 'package:doculens/models/document_record.dart';

// Import your new widgets
import 'package:doculens/widgets/editable_field_card.dart';
import 'package:doculens/widgets/edit_field_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final TelemetryService _telemetry = TelemetryService();
  final DatabaseService _db = DatabaseService();

  DocumentData _documentData = const DocumentData();
  XFile? _capturedImage;
  bool _isProcessing = false;
  bool _hasScanned = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _telemetry.logScreenView('scanner_screen');
  }

  Future<void> _scanDocument() async {
    if (_isProcessing) return;

    final XFile? pickedImage = await _imagePicker.pickImage(source: ImageSource.camera);
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
        _hasScanned = true;
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
      await _telemetry.logOcrFailed();
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showCustomSnackBar('OCR failed, please try again', isError: true);
    }
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (!_hasScanned) return;

    // Use the new dialog widget pattern for the name dialog too
    final docName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final nameController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Name Document', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. My Aadhaar Card'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) Navigator.pop(ctx, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (docName == null || docName.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final permanentPath = await _db.copyImageToVault(_capturedImage!.path);
      final fields = <DocumentField>[];

if (_documentData.name.isNotEmpty) {
  fields.add(DocumentField(documentId: 0, fieldName: 'Name', fieldValue: _documentData.name));
}

if (_documentData.dob.isNotEmpty) {
  fields.add(DocumentField(documentId: 0, fieldName: 'Date of Birth', fieldValue: _documentData.dob));
}

if (_documentData.gender.isNotEmpty) {
  fields.add(DocumentField(documentId: 0, fieldName: 'Gender', fieldValue: _documentData.gender));
}

      final record = DocumentRecord(name: docName, imagePath: permanentPath, createdAt: DateTime.now(), fields: fields);
      await _db.insertDocument(record);

      if (!mounted) return;
      _showCustomSnackBar('Document saved successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('Failed to save. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
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
                  flex: 4,
                  child: GestureDetector(
                    onTap: _scanDocument,
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _capturedImage == null ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                          width: _capturedImage == null ? 2 : 1,
                        ),
                      ),
                      child: _capturedImage == null
                          ? _buildEmptyScannerState()
                          : _buildImagePreviewState(),
                    ),
                  ),
                ).animate().fade(duration: 400.ms),

                const SizedBox(height: 24),

                // --- Bottom Section: Extracted Data ---
                const Text(
                  'Extracted Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 16),

                Expanded(
                  flex: 6,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      EditableFieldCard(
                        label: 'Name',
                        value: _documentData.name,
                        confidence: _documentData.nameConfidence,
                        hasScanned: _hasScanned,
                        delayMs: 300,
                        onEdit: () => EditFieldDialog.show(
                          context: context,
                          title: 'Name',
                          initialValue: _documentData.name,
                          onSave: (val) {
                            setState(() => _documentData = _documentData.copyWith(name: val));
                            _telemetry.logFieldEdited('name');
                          },
                        ),
                      ),
                      EditableFieldCard(
                        label: 'Date of Birth',
                        value: _documentData.dob,
                        confidence: _documentData.dobConfidence,
                        hasScanned: _hasScanned,
                        delayMs: 400,
                        onEdit: () => EditFieldDialog.show(
                          context: context,
                          title: 'Date of Birth',
                          initialValue: _documentData.dob,
                          onSave: (val) {
                            setState(() => _documentData = _documentData.copyWith(dob: val));
                            _telemetry.logFieldEdited('dob');
                          },
                        ),
                      ),
                      EditableFieldCard(
                        label: 'Gender',
                        value: _documentData.gender,
                        confidence: _documentData.genderConfidence,
                        hasScanned: _hasScanned,
                        delayMs: 500,
                        onEdit: () => EditFieldDialog.show(
                          context: context,
                          title: 'Gender',
                          initialValue: _documentData.gender,
                          onSave: (val) {
                            setState(() => _documentData = _documentData.copyWith(gender: val));
                            _telemetry.logFieldEdited('gender');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Save Button ---
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_hasScanned && !_isSaving) ? _saveDocument : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save to Vault'),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),

          // --- Processing Overlay (Light Glassmorphism) ---
          if (_isProcessing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 24),
                        const Text(
                          'Extracting details...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  // --- Viewport UI Helpers ---

  Widget _buildEmptyScannerState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.document_scanner_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to Scan ID',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ensure the document is well-lit',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildImagePreviewState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
        // Faint bottom shadow to make the retake button pop
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12, right: 12,
          child: OutlinedButton.icon(
            onPressed: _scanDocument,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ],
    );
  }
}