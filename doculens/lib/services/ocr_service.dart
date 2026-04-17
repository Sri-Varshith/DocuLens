class OcrService {
  Future<Map<String, dynamic>> extractDocumentFields(String imagePath) async {
    // Placeholder for ML Kit OCR extraction logic.
    return <String, dynamic>{
      'name': null,
      'dob': null,
      'gender': null,
      'confidence': <String, double>{
        'name': 0.0,
        'dob': 0.0,
        'gender': 0.0,
      },
    };
  }
}
