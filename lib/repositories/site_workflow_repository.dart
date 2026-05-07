import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/config/cargo_statuses.dart';
import '../models/cargo_model.dart';
import '../models/document_model.dart';
import '../models/site_workflow_models.dart';
import '../models/user_model.dart';

class SiteWorkflowRepository {
  SiteWorkflowRepository._();
  static final SiteWorkflowRepository instance = SiteWorkflowRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('cargoApplications');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('siteNotifications');

  CollectionReference<Map<String, dynamic>> get _activity =>
      _firestore.collection('activityLogs');

  CollectionReference<Map<String, dynamic>> get _documents =>
      _firestore.collection('cargoDocuments');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('userReports');

  CollectionReference<Map<String, dynamic>> get _serviceRequests =>
      _firestore.collection('serviceRequests');

  CollectionReference<Map<String, dynamic>> get _companyProfiles =>
      _firestore.collection('companyProfiles');

  Stream<List<CargoApplicationModel>> watchAllApplications() {
    return _applications.limit(300).snapshots().map((snap) {
      final items = snap.docs.map(CargoApplicationModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<CargoApplicationModel>> watchApplicationsForUser(UserModel user) {
    if (user.isAdmin) return watchAllApplications();

    final field = user.isCarrier ? 'applicantId' : 'ownerId';
    return _applications
        .where(field, isEqualTo: user.uid)
        .limit(160)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(CargoApplicationModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<CargoApplicationModel>> watchUserApplications(String userId) {
    return _applications
        .where('applicantId', isEqualTo: userId)
        .limit(120)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(CargoApplicationModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<SiteNotificationModel>> watchNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .limit(80)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(SiteNotificationModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<ActivityLogModel>> watchActivity(String userId) {
    return _activity
        .where('visibleTo', arrayContains: userId)
        .limit(120)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(ActivityLogModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<DocumentModel>> watchCargoDocuments(String cargoId) {
    return _documents
        .where('cargoId', isEqualTo: cargoId)
        .limit(80)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(DocumentModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<UserReportModel>> watchReports(UserModel admin) {
    if (!admin.isAdmin) {
      return Stream.error(Exception('Недостаточно прав администратора'));
    }

    return _reports.limit(120).snapshots().map((snap) {
      final items = snap.docs.map(UserReportModel.fromFirestore).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<Map<String, dynamic>?> watchCompanyProfile(String uid) {
    return _companyProfiles.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  Future<void> saveCompanyProfile({
    required UserModel user,
    required String organizationName,
    required String businessType,
    required String bin,
    required String phone,
    required String address,
    required String description,
  }) async {
    await _companyProfiles.doc(user.uid).set({
      'userId': user.uid,
      'userName': user.displayName,
      'organizationName': organizationName.trim(),
      'businessType': businessType.trim(),
      'bin': bin.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ServiceRequestModel>> watchServiceRequests(
    String userId, {
    String? type,
  }) {
    return _serviceRequests
        .where('userId', isEqualTo: userId)
        .limit(80)
        .snapshots()
        .map((snap) {
      var items = snap.docs.map(ServiceRequestModel.fromFirestore).toList();
      if (type != null) {
        items = items.where((item) => item.type == type).toList();
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> createServiceRequest({
    required UserModel user,
    required String type,
    required String title,
    required String message,
    Map<String, Object?> metadata = const {},
  }) async {
    final ref = _serviceRequests.doc();
    final batch = _firestore.batch();
    batch.set(ref, {
      'userId': user.uid,
      'userName': user.displayName,
      'type': type,
      'title': title.trim(),
      'message': message.trim(),
      'metadata': metadata,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _addActivityToBatch(
      batch,
      title: _serviceTypeTitle(type),
      body: title.trim().isEmpty ? message.trim() : title.trim(),
      actor: user,
      cargo: null,
      type: 'service_request',
      visibleTo: [user.uid],
    );

    await batch.commit();
  }

  Future<void> applyToCargo({
    required CargoModel cargo,
    required UserModel applicant,
    required String note,
  }) async {
    if (cargo.ownerId == applicant.uid) {
      throw Exception('Нельзя откликнуться на свой груз');
    }
    if (cargo.carrierId != null && cargo.carrierId!.isNotEmpty) {
      throw Exception('На этот груз уже назначен исполнитель');
    }

    final applicationId = '${cargo.id}_${applicant.uid}';
    final batch = _firestore.batch();
    final applicationRef = _applications.doc(applicationId);

    batch.set(
      applicationRef,
      {
        'cargoId': cargo.id,
        'cargoTitle': cargo.title,
        'ownerId': cargo.ownerId,
        'applicantId': applicant.uid,
        'applicantName': applicant.displayName,
        'applicantUsername': applicant.displayUsername,
        'status': 'pending',
        'note': note.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (cargo.ownerId != null) {
      _addNotificationToBatch(
        batch,
        userId: cargo.ownerId!,
        title: 'Новый отклик на груз',
        body: '${applicant.displayName} хочет взять "${cargo.title}"',
        type: 'application',
        relatedId: cargo.id,
      );
    }

    _addActivityToBatch(
      batch,
      title: 'Отклик на груз',
      body: '${applicant.displayName} откликнулся на "${cargo.title}"',
      actor: applicant,
      cargo: cargo,
      type: 'application',
      visibleTo: _visibleTo(cargo, applicant.uid),
    );

    await batch.commit();
  }

  Future<void> decideApplication({
    required CargoApplicationModel application,
    required CargoModel cargo,
    required UserModel owner,
    required bool accepted,
  }) async {
    final batch = _firestore.batch();
    final applicationRef = _applications.doc(application.id);
    final nextStatus = accepted ? 'accepted' : 'declined';

    batch.set(
      applicationRef,
      {
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (accepted) {
      batch.update(_firestore.collection('cargos').doc(cargo.id), {
        // Write both legacy and new fields for backward compatibility
        'driverId': application.applicantId,
        'driverName': application.applicantName,
        'executorId': application.applicantId,
        'executorName': application.applicantName,
        // executorSelected = carrier chosen, waiting for trip confirmation
        'status': CargoStatus.executorSelected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    _addNotificationToBatch(
      batch,
      userId: application.applicantId,
      title: accepted ? 'Отклик принят' : 'Отклик отклонен',
      body: accepted
          ? 'Вас назначили на груз "${cargo.title}"'
          : 'Отклик на "${cargo.title}" отклонен',
      type: 'application',
      relatedId: cargo.id,
    );

    _addActivityToBatch(
      batch,
      title: accepted ? 'Исполнитель назначен' : 'Отклик отклонен',
      body: accepted
          ? '${application.applicantName} назначен на "${cargo.title}"'
          : '${application.applicantName} не назначен на "${cargo.title}"',
      actor: owner,
      cargo: cargo,
      type: 'application',
      visibleTo: _visibleTo(cargo, application.applicantId),
    );

    await batch.commit();

    if (accepted) {
      final pending = await _applications
          .where('cargoId', isEqualTo: cargo.id)
          .where('status', isEqualTo: 'pending')
          .get();
      final declineBatch = _firestore.batch();
      for (final doc in pending.docs) {
        if (doc.id == application.id) continue;
        declineBatch.set(
          doc.reference,
          {
            'status': 'declined',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await declineBatch.commit();
    }
  }

  Future<void> updateCargoStatus({
    required CargoModel cargo,
    required UserModel actor,
    required String status,
  }) async {
    // Always store canonical English status keys; legacy values are normalised on read
    final canonicalStatus = CargoStatus.fromLegacy(status);
    final batch = _firestore.batch();
    batch.update(_firestore.collection('cargos').doc(cargo.id), {
      'status': canonicalStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final recipients = _visibleTo(cargo, actor.uid);
    final isDelivered = canonicalStatus == CargoStatus.delivered;
    for (final uid in recipients.where((uid) => uid != actor.uid)) {
      _addNotificationToBatch(
        batch,
        userId: uid,
        title: isDelivered
            ? 'Груз доставлен в пункт назначения'
            : 'Статус груза изменен',
        body: isDelivered
            ? '"${cargo.title}" успешно доставлен в ${cargo.to}'
            : '"${cargo.title}" теперь: ${CargoStatus.getDisplayStatus(canonicalStatus)}',
        type: 'status',
        relatedId: cargo.id,
      );
    }

    _addActivityToBatch(
      batch,
      title: 'Статус обновлен',
      body:
          '"${cargo.title}" теперь: ${CargoStatus.getDisplayStatus(canonicalStatus)}',
      actor: actor,
      cargo: cargo,
      type: 'status',
      visibleTo: recipients,
    );

    await batch.commit();
  }

  Future<DocumentModel> uploadCargoDocument({
    required CargoModel cargo,
    required UserModel uploader,
    required XFile file,
  }) async {
    final fileName = _safeFileName(file.name);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw Exception('Файл пустой');

    final contentType = file.mimeType ?? _guessMimeType(fileName);
    final storageRef = _storage.ref().child(
          'cargo_documents/${cargo.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
    final upload = await storageRef.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'public,max-age=300',
        customMetadata: {
          'cargoId': cargo.id,
          'uploaderId': uploader.uid,
        },
      ),
    );
    final url = await upload.ref.getDownloadURL();

    final docRef = _documents.doc();
    final extension = fileName.contains('.') ? fileName.split('.').last : '';
    final data = {
      'title': fileName,
      'description': 'Документ к грузу ${cargo.title}',
      'fileUrl': url,
      'fileName': fileName,
      'fileType': extension,
      'fileSize': bytes.length,
      'cargoId': cargo.id,
      'uploadedBy': uploader.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'tags': ['cargo'],
      'isActive': true,
    };

    final batch = _firestore.batch();
    batch.set(docRef, data);

    for (final uid in _visibleTo(cargo, uploader.uid).where(
      (uid) => uid != uploader.uid,
    )) {
      _addNotificationToBatch(
        batch,
        userId: uid,
        title: 'Новый документ',
        body: '$fileName добавлен к грузу "${cargo.title}"',
        type: 'document',
        relatedId: cargo.id,
      );
    }

    _addActivityToBatch(
      batch,
      title: 'Документ добавлен',
      body: '$fileName прикреплен к "${cargo.title}"',
      actor: uploader,
      cargo: cargo,
      type: 'document',
      visibleTo: _visibleTo(cargo, uploader.uid),
    );
    await batch.commit();

    final snapshot = await docRef.get();
    return DocumentModel.fromFirestore(snapshot);
  }

  Future<void> markNotificationRead(String id) async {
    await _notifications.doc(id).set(
      {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> reportUser({
    required UserModel reporter,
    required UserModel target,
    required String reason,
  }) async {
    final batch = _firestore.batch();
    final reportRef = _reports.doc();
    batch.set(reportRef, {
      'reporterId': reporter.uid,
      'reporterName': reporter.displayName,
      'targetId': target.uid,
      'targetName': target.displayName,
      'reason': reason.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _addActivityToBatch(
      batch,
      title: 'Жалоба на пользователя',
      body: '${reporter.displayName} пожаловался на ${target.displayName}',
      actor: reporter,
      cargo: null,
      type: 'report',
      visibleTo: [reporter.uid, target.uid],
    );

    await batch.commit();
  }

  Future<void> resolveReport({
    required UserModel admin,
    required String reportId,
  }) async {
    if (!admin.isAdmin) {
      throw Exception('Недостаточно прав администратора');
    }

    await _reports.doc(reportId).set(
      {
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _addNotificationToBatch(
    WriteBatch batch, {
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) {
    final ref = _notifications.doc();
    batch.set(ref, {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _addActivityToBatch(
    WriteBatch batch, {
    required String title,
    required String body,
    required UserModel actor,
    required CargoModel? cargo,
    required String type,
    required List<String> visibleTo,
  }) {
    final ref = _activity.doc();
    batch.set(ref, {
      'title': title,
      'body': body,
      'actorId': actor.uid,
      'actorName': actor.displayName,
      'cargoId': cargo?.id,
      'type': type,
      'visibleTo': visibleTo.toSet().toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  List<String> _visibleTo(CargoModel cargo, String fallbackUserId) {
    return <String>{
      fallbackUserId,
      if (cargo.ownerId?.isNotEmpty == true) cargo.ownerId!,
      // carrierId covers both legacy driverId and new executorId
      if (cargo.carrierId?.isNotEmpty == true) cargo.carrierId!,
    }.toList();
  }

  String _safeFileName(String value) {
    final name = value.trim().isEmpty ? 'document' : value.trim();
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-ЯёЁ._ -]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _guessMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }

  String _serviceTypeTitle(String type) {
    switch (type) {
      case 'insurance':
        return 'Заявка на страхование';
      case 'legal':
        return 'Запрос юристу';
      case 'support':
        return 'Обращение в техподдержку';
      default:
        return 'Сервисная заявка';
    }
  }
}
