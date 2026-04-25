import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:doculens/theme/app_theme.dart';

class EditableFieldCard extends StatelessWidget {
  final String label;
  final String value;
  final double confidence;
  final bool hasScanned;
  final int delayMs;
  final VoidCallback onEdit;

  const EditableFieldCard({
    super.key,
    required this.label,
    required this.value,
    required this.confidence,
    required this.hasScanned,
    required this.delayMs,
    required this.onEdit,
  });

  (Color, Color, String) _getBadgeStyle() {
    if (confidence >= 0.7) {
      return (const Color(0xFFD1FAE5), const Color(0xFF059669), 'High'); // Light/Dark Emerald
    }
    if (confidence >= 0.4) {
      return (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Medium'); // Light/Dark Amber
    }
    return (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Low'); // Light/Dark Red
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty
        ? (hasScanned ? 'Not detected' : 'Waiting for scan...')
        : value;
    
    final (badgeBg, badgeText, badgeLabel) = _getBadgeStyle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
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
                        label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: value.isEmpty && hasScanned
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
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
    ).animate().fade(delay: delayMs.ms).slideX(begin: 0.05, end: 0);
  }
}