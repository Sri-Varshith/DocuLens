import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:doculens/models/document_data.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  DocumentData _documentData = const DocumentData();
  XFile? _capturedImage;

  Future<void> _scanDocument() async {
    final XFile? pickedImage = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _capturedImage = pickedImage;
      // TODO(sriva): Add ML Kit OCR extraction logic and map values to _documentData.
      _documentData = _documentData.copyWith(
        name: _documentData.name,
        dob: _documentData.dob,
        gender: _documentData.gender,
        nameConfidence: _documentData.nameConfidence,
        dobConfidence: _documentData.dobConfidence,
        genderConfidence: _documentData.genderConfidence,
      );
    });
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required void Function(String value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.7) {
      return Colors.green;
    }
    if (confidence >= 0.4) {
      return Colors.yellow.shade700;
    }
    return Colors.red;
  }

  Widget _buildFieldCard({
    required String label,
    required String value,
    required double confidence,
    required VoidCallback onEdit,
  }) {
    final displayValue = value.isEmpty ? 'Not detected' : value;

    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(displayValue),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _confidenceColor(confidence),
            shape: BoxShape.circle,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 500,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: InkWell(
                        onTap: _scanDocument,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: constraints.maxHeight,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: _capturedImage == null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 48,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Tap to scan document',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_capturedImage!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildFieldCard(
              label: 'Name',
              value: _documentData.name,
              confidence: _documentData.nameConfidence,
              onEdit: () => _editField(
                title: 'Name',
                initialValue: _documentData.name,
                onSave: (value) {
                  setState(() {
                    _documentData = _documentData.copyWith(name: value);
                  });
                },
              ),
            ),
            _buildFieldCard(
              label: 'Date of Birth',
              value: _documentData.dob,
              confidence: _documentData.dobConfidence,
              onEdit: () => _editField(
                title: 'Date of Birth',
                initialValue: _documentData.dob,
                onSave: (value) {
                  setState(() {
                    _documentData = _documentData.copyWith(dob: value);
                  });
                },
              ),
            ),
            _buildFieldCard(
              label: 'Gender',
              value: _documentData.gender,
              confidence: _documentData.genderConfidence,
              onEdit: () => _editField(
                title: 'Gender',
                initialValue: _documentData.gender,
                onSave: (value) {
                  setState(() {
                    _documentData = _documentData.copyWith(gender: value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
