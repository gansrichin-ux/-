import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/delivery_report_model.dart';

class DeliveryReportService {
  DeliveryReportService._();
  static final DeliveryReportService instance = DeliveryReportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('delivery_reports');

  // Photo operations
  Future<String?> pickAndUploadPhoto(String cargoId, String driverId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(
        'delivery_reports/$cargoId/$driverId/$fileName',
      );

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> pickAndUploadMultiplePhotos(
    String cargoId,
    String driverId,
    List<String> existingPhotos,
  ) async {
    final photos = List<String>.from(existingPhotos);

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      for (final image in images) {
        final file = File(image.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final ref = _storage.ref().child(
          'delivery_reports/$cargoId/$driverId/$fileName',
        );

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        photos.add(downloadUrl);
      }
    } catch (e) {
      // Handle error
    }

    return photos;
  }

  Future<bool> deletePhoto(
    String cargoId,
    String driverId,
    String photoUrl,
  ) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Report operations
  Future<String> createReport({
    required String cargoId,
    required String driverId,
    List<String> photos = const [],
    String? signatureBase64,
    String? notes,
  }) async {
    final report = DeliveryReportModel(
      id: '', // Will be set by Firestore
      cargoId: cargoId,
      driverId: driverId,
      photos: photos,
      signatureBase64: signatureBase64,
      notes: notes,
      createdAt: DateTime.now(),
      status: DeliveryStatus.pending,
    );

    final docRef = await _reports.add(report.toFirestoreMap());
    return docRef.id;
  }

  Future<DeliveryReportModel?> getReport(String reportId) async {
    try {
      final doc = await _reports.doc(reportId).get();
      if (!doc.exists) return null;
      return DeliveryReportModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<List<DeliveryReportModel>> getReportsByCargo(String cargoId) async {
    try {
      final snapshot = await _reports
          .where('cargoId', isEqualTo: cargoId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DeliveryReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DeliveryReportModel>> getReportsByDriver(String driverId) async {
    try {
      final snapshot = await _reports
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DeliveryReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateReport(
    String reportId, {
    List<String>? photos,
    String? signatureBase64,
    String? notes,
    DeliveryStatus? status,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (photos != null) updates['photos'] = photos;
      if (signatureBase64 != null) updates['signatureBase64'] = signatureBase64;
      if (notes != null) updates['notes'] = notes;
      if (status != null) updates['status'] = status.toString();

      await _reports.doc(reportId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      final report = await getReport(reportId);
      if (report == null) return false;

      // Delete all associated photos
      for (final photoUrl in report.photos) {
        await deletePhoto(report.cargoId, report.driverId, photoUrl);
      }

      await _reports.doc(reportId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<List<DeliveryReportModel>> watchReportsByCargo(String cargoId) {
    return _reports
        .where('cargoId', isEqualTo: cargoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeliveryReportModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<DeliveryReportModel>> watchReportsByDriver(String driverId) {
    return _reports.where('driverId', isEqualTo: driverId).snapshots().map((
      snapshot,
    ) {
      final reports = snapshot.docs
          .map((doc) => DeliveryReportModel.fromFirestore(doc))
          .toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }
}
