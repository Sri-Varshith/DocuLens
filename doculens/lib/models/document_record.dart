class DocumentRecord {
  final int? id;
  final String name;
  final String imagePath;
  final DateTime createdAt;
  final List<DocumentField> fields;

  const DocumentRecord({
    this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    this.fields = const [],
  });
}

class DocumentField {
  final int? id;
  final int documentId;
  final String fieldName;
  final String fieldValue;

  const DocumentField({
    this.id,
    required this.documentId,
    required this.fieldName,
    required this.fieldValue,
  });
}