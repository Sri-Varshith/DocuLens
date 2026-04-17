import 'package:flutter/material.dart';

class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $percentage%'),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: value.clamp(0, 1)),
      ],
    );
  }
}
