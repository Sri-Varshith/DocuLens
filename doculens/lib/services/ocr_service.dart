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

  /// Your original heuristic logic, slightly cleaned up, acts as a fallback
  String _extractNameHeuristic(List<String> lines) {
    final nameLabels = ['name', 'name:', 'name -', 'name: '];
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      for (final label in nameLabels) {
        if (lower.startsWith(label)) {
          var value = line.substring(label.length).trim();
          // Strip any leading colons or hyphens that got attached to the value
          value = value.replaceAll(RegExp(r'^[:\-\s]+'), '').trim();
          if (value.isNotEmpty) return value;
        }
      }

      // Check if "NAME" is on its own line, and grab the line below it
      if (lower == 'name' && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        // Make sure the next line isn't just another label
        if (!nextLine.toLowerCase().contains('dob') && !nextLine.toLowerCase().contains('gender')) {
           return nextLine;
        }
      }
    }
    return '';
  }
}