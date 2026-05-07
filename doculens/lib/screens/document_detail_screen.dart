import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:doculens/models/document_record.dart';
import 'package:doculens/services/database_service.dart';
import 'package:doculens/services/telemetry_service.dart';
import 'package:doculens/theme/app_theme.dart';
import 'package:doculens/widgets/edit_field_dialog.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentRecord document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late DocumentRecord _document;
  final DatabaseService _db = DatabaseService();
  final TelemetryService _telemetry = TelemetryService();
  bool _imageExpanded = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  // Update a field both in the DB and in local state
  Future<void> _updateField(DocumentField field, String newValue) async {
    // Find the field index in our local list
    final index = _document.fields.indexWhere((f) => f.id == field.id);
    if (index == -1) return;

    // Update in DB
    await _db.updateField(field.id!, newValue);

    // Update local state so UI reflects immediately without refetching
    final updatedFields = List<DocumentField>.from(_document.fields);
    updatedFields[index] = DocumentField(
      id: field.id,
      documentId: field.documentId,
      fieldName: field.fieldName,
      fieldValue: newValue,
    );

    setState(() {
      _document = DocumentRecord(
        id: _document.id,
        name: _document.name,
        imagePath: _document.imagePath,
        createdAt: _document.createdAt,
        fields: updatedFields,
      );
    });

    _telemetry.logFieldEdited(field.fieldName);
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _document.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            GestureDetector(
              onTap: () => setState(() => _imageExpanded = !_imageExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _imageExpanded ? 340 : 200,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    File(_document.imagePath).existsSync()
                        ? Image.file(
                            File(_document.imagePath),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                              size: 48,
                            ),
                          ),
                    // Expand/collapse hint
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _imageExpanded
                                  ? Icons.compress_rounded
                                  : Icons.expand_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _imageExpanded ? 'Collapse' : 'Expand',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // --- Date saved ---
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(_document.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ).animate().fade(delay: 200.ms),

            const SizedBox(height: 28),

            // --- Fields Section ---
            const Text(
              'Document Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ).animate().fade(delay: 300.ms),

            const SizedBox(height: 16),

            // Build one card per saved field
            ..._document.fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;

              return _buildFieldCard(
                field: field,
                delayMs: 400 + (index * 100),
              );
            }),

            // Empty state if no fields were saved
            if (_document.fields.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    'No fields were saved for this document.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard({
    required DocumentField field,
    required int delayMs,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => EditFieldDialog.show(
            context: context,
            title: field.fieldName,
            initialValue: field.fieldValue,
            onSave: (newValue) => _updateField(field, newValue),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.fieldName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        field.fieldValue.isEmpty ? '—' : field.fieldValue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: delayMs.ms).slideY(begin: 0.05, end: 0);
  }
}