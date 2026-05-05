import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DocumentModel {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String? cargoId;
  final String? clientId;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> tags;
  final bool isActive;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.cargoId,
    this.clientId,
    this.uploadedBy,
    required this.createdAt,
    this.expiresAt,
    this.tags = const [],
    this.isActive = true,
  });

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      fileType: data['fileType'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      cargoId: data['cargoId'] as String?,
      clientId: data['clientId'] as String?,
      uploadedBy: data['uploadedBy'] as String?,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      expiresAt: _readDate(data['expiresAt']),
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      fileUrl: map['fileUrl'] as String,
      fileName: map['fileName'] as String,
      fileType: map['fileType'] as String,
      fileSize: map['fileSize'] as int,
      cargoId: map['cargoId'] as String?,
      clientId: map['clientId'] as String?,
      uploadedBy: map['uploadedBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      tags: List<String>.from(map['tags'] as List? ?? []),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'cargoId': cargoId,
      'clientId': clientId,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'tags': tags,
      'isActive': isActive,
    };
  }

  DocumentModel copyWith({
    String? title,
    String? description,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    String? cargoId,
    String? clientId,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? tags,
    bool? isActive,
  }) {
    return DocumentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      cargoId: cargoId ?? this.cargoId,
      clientId: clientId ?? this.clientId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiry = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  DocumentType get documentType {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'doc':
      case 'docx':
        return DocumentType.word;
      case 'xls':
      case 'xlsx':
        return DocumentType.excel;
      case 'ppt':
      case 'pptx':
        return DocumentType.powerpoint;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return DocumentType.image;
      case 'txt':
        return DocumentType.text;
      default:
        return DocumentType.other;
    }
  }
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

enum DocumentType { pdf, word, excel, powerpoint, image, text, other }

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.word:
        return 'Word';
      case DocumentType.excel:
        return 'Excel';
      case DocumentType.powerpoint:
        return 'PowerPoint';
      case DocumentType.image:
        return 'Изображение';
      case DocumentType.text:
        return 'Текст';
      case DocumentType.other:
        return 'Другое';
    }
  }

  String get iconName {
    switch (this) {
      case DocumentType.pdf:
        return 'picture_as_pdf';
      case DocumentType.word:
        return 'description';
      case DocumentType.excel:
        return 'table_chart';
      case DocumentType.powerpoint:
        return 'slideshow';
      case DocumentType.image:
        return 'image';
      case DocumentType.text:
        return 'text_snippet';
      case DocumentType.other:
        return 'insert_drive_file';
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.pdf:
        return const Color(0xFFEF4444);
      case DocumentType.word:
        return const Color(0xFF3B82F6);
      case DocumentType.excel:
        return const Color(0xFF22C55E);
      case DocumentType.powerpoint:
        return const Color(0xFFF59E0B);
      case DocumentType.image:
        return const Color(0xFF8B5CF6);
      case DocumentType.text:
        return const Color(0xFF64748B);
      case DocumentType.other:
        return const Color(0xFF94A3B8);
    }
  }
}
