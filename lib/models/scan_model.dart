import 'package:uuid/uuid.dart';

class ScanModel {
  final String id;
  final String imagePath;
  final String extractedText;
  final String language;
  final DateTime createdAt;
  final String? title; // titre optionnel (ex : "Reçu 12/05")

  ScanModel({
    String? id,
    required this.imagePath,
    required this.extractedText,
    required this.language,
    DateTime? createdAt,
    this.title,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // ─── Persistence SQLite ───────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'extractedText': extractedText,
    'language': language,
    'createdAt': createdAt.toIso8601String(),
    'title': title,
  };

  factory ScanModel.fromMap(Map<String, dynamic> map) => ScanModel(
    id: map['id'] as String,
    imagePath: map['imagePath'] as String,
    extractedText: map['extractedText'] as String,
    language: map['language'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    title: map['title'] as String?,
  );

  ScanModel copyWith({
    String? imagePath,
    String? extractedText,
    String? language,
    String? title,
  }) => ScanModel(
    id: id,
    imagePath: imagePath ?? this.imagePath,
    extractedText: extractedText ?? this.extractedText,
    language: language ?? this.language,
    createdAt: createdAt,
    title: title ?? this.title,
  );
}
