import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:doculens/models/document_data.dart';

class OcrService {
  /// Runs on-device text recognition and maps lines to [DocumentData] fields.
  Future<DocumentData> extractData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;
      print('Full OCR text: $fullText');

      final name = _extractName(fullText);
      final dob = _extractDob(fullText);
      final gender = _extractGender(fullText);

      return DocumentData(
        name: name,
        dob: dob,
        gender: gender,
        nameConfidence: name.isNotEmpty ? 0.9 : 0.0,
        dobConfidence: dob.isNotEmpty ? 0.9 : 0.0,
        genderConfidence: gender.isNotEmpty ? 0.9 : 0.0,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  /// Non-empty [sameLineRemainder] wins; otherwise uses the next raw line
  /// (trimmed) when it is non-empty.
  static String _valueOnSameLineOrNext(
    List<String> rawLines,
    int lineIndex,
    String sameLineRemainder,
  ) {
    final trimmed = sameLineRemainder.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (lineIndex + 1 < rawLines.length) {
      final next = rawLines[lineIndex + 1].trim();
      if (next.isNotEmpty) {
        return next;
      }
    }
    return '';
  }

  static String _extractName(String text) {
    final rawLines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final lower = line.toLowerCase();
      const label = 'name:';
      final idx = lower.indexOf(label);
      if (idx < 0) {
        continue;
      }
      final afterLabel = line.substring(idx + label.length);
      final value = _valueOnSameLineOrNext(rawLines, i, afterLabel);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static const List<String> _dobLabels = [
    'date of birth:',
    'd.o.b:',
    'dob:',
  ];

  static String _extractDob(String text) {
    final rawLines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final lower = line.toLowerCase();
      for (final label in _dobLabels) {
        final idx = lower.indexOf(label);
        if (idx < 0) {
          continue;
        }
        final afterLabel = line.substring(idx + label.length);
        final value = _valueOnSameLineOrNext(rawLines, i, afterLabel);
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  static String _extractGender(String text) {
    final rawLines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      final lower = line.toLowerCase();
      const genderLabel = 'gender:';
      if (lower.contains(genderLabel)) {
        final idx = lower.indexOf(genderLabel);
        final afterLabel = line.substring(idx + genderLabel.length);
        final value = _valueOnSameLineOrNext(rawLines, i, afterLabel);
        if (value.isNotEmpty) {
          return value;
        }
      }
      final sexMatch = RegExp(r'\bsex\s*:', caseSensitive: false)
          .firstMatch(line);
      if (sexMatch != null) {
        final afterLabel = line.substring(sexMatch.end);
        final value = _valueOnSameLineOrNext(rawLines, i, afterLabel);
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }
}
