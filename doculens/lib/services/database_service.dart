import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doculens/models/document_record.dart';

class DatabaseService {
  // Singleton pattern — same instance reused everywhere
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'doculens.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table 1: one row per saved document
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Table 2: one row per field, linked to a document
    await db.execute('''
      CREATE TABLE document_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        fieldName TEXT NOT NULL,
        fieldValue TEXT NOT NULL,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');
  }

  // Copies image from temp camera cache to permanent app storage
  // Returns the new permanent path
  Future<String> copyImageToVault(String tempImagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/doculens_images');
    if (!vaultDir.existsSync()) await vaultDir.create(recursive: true);

    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(tempImagePath).copy('${vaultDir.path}/$fileName');
    return savedImage.path;
  }

  // Save a document + all its fields in one atomic transaction
  Future<int> insertDocument(DocumentRecord doc) async {
    final db = await database;

    return db.transaction<int>((txn) async {
      // Step 1: insert the document row, get back the auto-generated id
      final docId = await txn.insert('documents', {
        'name': doc.name,
        'imagePath': doc.imagePath,
        'createdAt': doc.createdAt.toIso8601String(),
      });

      // Step 2: insert each field row linked to that id
      for (final field in doc.fields) {
        await txn.insert('document_fields', {
          'documentId': docId,
          'fieldName': field.fieldName,
          'fieldValue': field.fieldValue,
        });
      }

      return docId;
    });
  }

  // Fetch all documents with their fields, newest first
  Future<List<DocumentRecord>> getAllDocuments() async {
    final db = await database;
    final docRows = await db.query('documents', orderBy: 'createdAt DESC');

    final records = <DocumentRecord>[];
    for (final row in docRows) {
      final docId = row['id'] as int;
      final fieldRows = await db.query(
        'document_fields',
        where: 'documentId = ?',
        whereArgs: [docId],
      );

      final fields = fieldRows.map((f) => DocumentField(
        id: f['id'] as int?,
        documentId: docId,
        fieldName: f['fieldName'] as String,
        fieldValue: f['fieldValue'] as String,
      )).toList();

      records.add(DocumentRecord(
        id: docId,
        name: row['name'] as String,
        imagePath: row['imagePath'] as String,
        createdAt: DateTime.parse(row['createdAt'] as String),
        fields: fields,
      ));
    }
    return records;
  }

  // Delete document — cascade in schema also deletes its fields automatically
  Future<void> deleteDocument(int id) async {
    final db = await database;

    // Fetch image path first so we can delete the file too
    final rows = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final imagePath = rows.first['imagePath'] as String;
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) await imageFile.delete();
    }

    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }
}