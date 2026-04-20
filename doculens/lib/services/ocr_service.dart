import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:doculens/models/document_data.dart';

class OcrService {
  Future<DocumentData> extractData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    // Initialize both ML Kit models
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);

    String extractedName = '';
    String extractedDob = '';
    String extractedGender = '';
    double nameConf = 0.0;
    double dobConf = 0.0;
    double genderConf = 0.0;

    try {
      // It's best practice to ensure the entity extraction model is downloaded
      final modelManager = EntityExtractorModelManager();
      await modelManager.downloadModel(EntityExtractorLanguage.english.name);

      // 1. Get raw text from the image
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;
      
      // Keep a list of lines for our fallback heuristics
      final lines = rawText
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

// 2. Intelligent Extraction using ML Kit Entity Extractor (For DOB only)
      final annotations = await entityExtractor.annotateText(rawText);
      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          // ML Kit supports dateTime, but not person names
          if (entity.type == EntityType.dateTime && extractedDob.isEmpty) {
            extractedDob = annotation.text;
            dobConf = 0.8; // ML Model detected this as a date
          }
        }
      }

      // 3. Regex Fallbacks
      // Fallback for DOB if Entity Extractor misses it
      if (extractedDob.isEmpty) {
        final dobRegex = RegExp(
            r'\b(?:0[1-9]|[12][0-9]|3[01])[-/.\s](?:0[1-9]|1[012]|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[-/.\s](?:19|20)\d\d\b',
            caseSensitive: false);
        final match = dobRegex.firstMatch(rawText);
        if (match != null) {
          extractedDob = match.group(0) ?? '';
          dobConf = 0.9;
        }
      }

      extractedGender = _extractGender(lines);
      if (extractedGender.isNotEmpty) genderConf = 0.9;

      // 4. Heuristic Fallback for Name
      // Since ML Kit can't find names, we always use the heuristic for this field
      extractedName = _extractNameHeuristic(lines);
      if (extractedName.isNotEmpty) nameConf = 0.6;

      return DocumentData(
        name: extractedName,
        dob: extractedDob,
        gender: extractedGender,
        nameConfidence: nameConf,
        dobConfidence: dobConf,
        genderConfidence: genderConf,
      );
    } catch (e) {
      // Handle exceptions (e.g., return empty data or rethrow)
      print("Error during OCR extraction: $e");
      return DocumentData(
        name: '', dob: '', gender: '', 
        nameConfidence: 0, dobConfidence: 0, genderConfidence: 0
      );
    } finally {
      // Always close resources to prevent memory leaks
      await textRecognizer.close();
      await entityExtractor.close();
    }
  }

  /// Extracts gender by looking for specific keywords, handling OCR typos near the label
  String _extractGender(List<String> lines) {
    // Looks for explicit words regardless of surrounding garbage text
    final genderRegex = RegExp(r'\b(Male|Female|M|F|Transgender)\b', caseSensitive: false);
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      
      // If the line contains a gender indicator label
      if (lower.contains('gender') || lower.contains('sex')) {
        // Check if the value is on the same line
        final match = genderRegex.firstMatch(line);
        if (match != null) return _formatGender(match.group(0)!);
        
        // Check if the value got pushed to the next line
        if (i + 1 < lines.length) {
          final nextMatch = genderRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) return _formatGender(nextMatch.group(0)!);
        }
      }
    }
    
    // Broad pass: If "Gender" label was misread by OCR entirely, just look for the word "Male" or "Female"
    for (var line in lines) {
      final match = genderRegex.firstMatch(line);
      // Ensure we don't accidentally grab an 'M' or 'F' from a random long serial number
      if (match != null && line.length < 20) {
        return _formatGender(match.group(0)!);
      }
    }
    
    return '';
  }

  /// Normalizes the gender output to a standard format
  String _formatGender(String rawGender) {
    final lower = rawGender.toLowerCase();
    if (lower == 'm' || lower == 'male') return 'Male';
    if (lower == 'f' || lower == 'female') return 'Female';
    return rawGender;
  }

String _extractNameHeuristic(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // 1. Broad match: Catches "Name:", "Full Name:", "Student Name", etc.
      if (lower.contains('name')) {
        
        // Find where 'name' is in the string, and grab everything after it
        final idx = lower.indexOf('name');
        String extractedValue = line.substring(idx + 4); // 4 is the length of 'name'
        
        // Use Regex to obliterate any leading colons, hyphens, and unlimited spaces
        extractedValue = extractedValue.replaceAll(RegExp(r'^[:\-\s]+'), '').trim();

        // Case A: The value was on the same line (e.g., "name:           rahul")
        if (extractedValue.isNotEmpty && !_isForbiddenLabel(extractedValue)) {
          return extractedValue;
        }

        // Case B: The OCR broke "rahul" onto the very next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          
          // Ensure we don't accidentally grab "Grade: 10" if 'rahul' was missing
          if (nextLine.isNotEmpty && !_isForbiddenLabel(nextLine)) {
            return nextLine;
          }
        }
      }
    }

    // 2. Structural Fallback: If the label "Name" was totally destroyed by glare
    // Look for a line that is purely alphabetical with at least one space (First Last)
    final pureNameRegex = RegExp(r'^[A-Za-z]+\s+[A-Za-z\s]+$'); 
    for (var line in lines) {
      if (pureNameRegex.hasMatch(line) && !_isForbiddenLabel(line)) {
        return line;
      }
    }

    return '';
  }

  /// Safety Net: Prevents the Name extractor from stealing other data points
  bool _isForbiddenLabel(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dob') || 
           lower.contains('date') || 
           lower.contains('gender') || 
           lower.contains('sex') || 
           lower.contains('grade') || 
           lower.contains('class') ||
           lower.contains('father') ||
           lower.contains('mother') ||
           lower.contains('blood') ||
           lower.contains('id') ||
           lower.contains('no');
  }
}