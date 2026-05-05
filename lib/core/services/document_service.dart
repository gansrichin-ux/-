import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/document_model.dart';

class DocumentService {
  DocumentService._();
  static final DocumentService instance = DocumentService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _documents =>
      _firestore.collection('documents');

  // Upload document
  Future<String?> uploadDocument({
    required String title,
    required String description,
    required File file,
    String? cargoId,
    String? clientId,
    String? uploadedBy,
    List<String> tags = const [],
    DateTime? expiresAt,
  }) async {
    try {
      // Upload file to Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child(
        'documents/${uploadedBy ?? 'unknown'}/$fileName',
      );

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create document record
      final document = DocumentModel(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        fileUrl: downloadUrl,
        fileName: file.path.split('/').last,
        fileType: file.path.split('.').last.toLowerCase(),
        fileSize: await file.length(),
        cargoId: cargoId,
        clientId: clientId,
        uploadedBy: uploadedBy,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        tags: tags,
      );

      final docRef = await _documents.add(document.toMap());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Pick and upload document
  Future<String?> pickAndUploadDocument({
    String? cargoId,
    String? clientId,
    String? uploadedBy,
  }) async {
    try {
      // FilePicker functionality temporarily disabled
      // TODO: Add file_picker dependency to pubspec.yaml
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get document by ID
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final doc = await _documents.doc(documentId).get();
      if (!doc.exists) return null;
      return DocumentModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final snapshot = await _documents
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get documents by cargo
  Future<List<DocumentModel>> getDocumentsByCargo(String cargoId) async {
    try {
      final snapshot = await _documents
          .where('cargoId', isEqualTo: cargoId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get documents by client
  Future<List<DocumentModel>> getDocumentsByClient(String clientId) async {
    try {
      final snapshot = await _documents
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get documents by uploader
  Future<List<DocumentModel>> getDocumentsByUploader(String uploadedBy) async {
    try {
      final snapshot = await _documents
          .where('uploadedBy', isEqualTo: uploadedBy)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      final snapshot = await _documents
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update document
  Future<bool> updateDocument(DocumentModel document) async {
    try {
      await _documents.doc(document.id).update(document.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete document (soft delete)
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _documents.doc(documentId).update({'isActive': false});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Restore document
  Future<bool> restoreDocument(String documentId) async {
    try {
      await _documents.doc(documentId).update({'isActive': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get download URL
  Future<String?> getDownloadUrl(String documentId) async {
    try {
      final document = await getDocument(documentId);
      return document?.fileUrl;
    } catch (e) {
      return null;
    }
  }

  // Get expiring documents
  Future<List<DocumentModel>> getExpiringDocuments({int days = 7}) async {
    try {
      final futureDate = DateTime.now().add(Duration(days: days));
      final snapshot = await _documents
          .where(
            'expiresAt',
            isLessThanOrEqualTo: Timestamp.fromDate(futureDate),
          )
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get expired documents
  Future<List<DocumentModel>> getExpiredDocuments() async {
    try {
      final snapshot = await _documents
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((doc) => doc.isActive)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Watch all documents stream
  Stream<List<DocumentModel>> watchAllDocuments() {
    return _documents
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc))
              .where((doc) => doc.isActive)
              .toList(),
        );
  }

  // Watch documents by cargo stream
  Stream<List<DocumentModel>> watchDocumentsByCargo(String cargoId) {
    return _documents
        .where('cargoId', isEqualTo: cargoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc))
              .where((doc) => doc.isActive)
              .toList(),
        );
  }

  // Watch documents by client stream
  Stream<List<DocumentModel>> watchDocumentsByClient(String clientId) {
    return _documents
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc))
              .where((doc) => doc.isActive)
              .toList(),
        );
  }

  Stream<List<DocumentModel>> watchDocumentsByUploader(String uploadedBy) {
    return _documents
        .where('uploadedBy', isEqualTo: uploadedBy)
        .snapshots()
        .map((snapshot) {
          final documents = snapshot.docs
              .map((doc) => DocumentModel.fromFirestore(doc))
              .where((doc) => doc.isActive)
              .toList();
          documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return documents;
        });
  }
}
