import 'package:flutter/material.dart';
import 'package:doculens/theme/app_theme.dart';

class EditFieldDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final Function(String) onSave;

  const EditFieldDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onSave,
  });

  // A helper method to easily show this dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditFieldDialog(
        title: title,
        initialValue: initialValue,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<EditFieldDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent, // Removes Android's default purple tint
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Edit ${widget.title}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: widget.title,
          // Uses the clean input decoration from your AppTheme
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}