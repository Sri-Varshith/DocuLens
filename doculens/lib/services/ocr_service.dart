import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:doculens/models/document_data.dart';

class OcrService {
  Future<DocumentData> extractData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;
      print('Full OCR text: $fullText');

      final lines = fullText.split(RegExp(r'\r?\n'));

      final name = _extractName(lines);
      final dob = _extractDob(lines);
      final gender = _extractGender(lines);

      print('Name: $name');
      print('DOB: $dob');
      print('Gender: $gender');

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

  static String _extractName(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      // Format: "Name: John" or "NAME: John"
      if (lower.contains('name:')) {
        final idx = lower.indexOf('name:');
        final after = line.substring(idx + 5).trim();
        // Remove leading colon if present
        final value = after.startsWith(':') ? after.substring(1).trim() : after;
        if (value.isNotEmpty) return value;
        // Check next line
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          final cleaned = next.startsWith(':') ? next.substring(1).trim() : next;
          if (cleaned.isNotEmpty && !_isLabel(cleaned)) return cleaned;
        }
      }

      // Format: "NAME\n:John" — label on one line, colon+value on next
      if (lower == 'name') {
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          final cleaned = next.startsWith(':') ? next.substring(1).trim() : next;
          if (cleaned.isNotEmpty && !_isLabel(cleaned)) return cleaned;
        }
      }
    }
    return '';
  }

  static String _extractDob(List<String> lines) {
    final dobLabels = ['date of birth:', 'd.o.b:', 'dob:', 'date of birth', 'd.o.b', 'dob'];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      for (final label in dobLabels) {
        if (lower.contains(label)) {
          final idx = lower.indexOf(label);
          final after = line.substring(idx + label.length).trim();
          final value = after.startsWith(':') ? after.substring(1).trim() : after;
          if (value.isNotEmpty) return value;
          // Check next line
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            final cleaned = next.startsWith(':') ? next.substring(1).trim() : next;
            if (cleaned.isNotEmpty && !_isLabel(cleaned)) return cleaned;
          }
        }
      }
    }
    return '';
  }

  static String _extractGender(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (lower.contains('gender:') || lower.contains('sex:')) {
        final idx = lower.contains('gender:') ? lower.indexOf('gender:') + 7 : lower.indexOf('sex:') + 4;
        final after = line.substring(idx).trim();
        final value = after.startsWith(':') ? after.substring(1).trim() : after;
        if (value.isNotEmpty) return value;
        if (i + 1 < lines.length) {
          final next = lines[i + 1].trim();
          final cleaned = next.startsWith(':') ? next.substring(1).trim() : next;
          if (cleaned.isNotEmpty && !_isLabel(cleaned)) return cleaned;
        }
      }

      // Blood group sometimes appears near gender on ID cards
      // Check for M/F/Male/Female standalone
      if (['male', 'female', 'm', 'f'].contains(lower.trim())) {
        return line.trim();
      }
    }
    return '';
  }

  // Checks if a line looks like a label (all caps or ends with colon)
  static bool _isLabel(String line) {
    return line.endsWith(':') || line == line.toUpperCase();
  }
}