import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String cargoId) =>
      _firestore.collection('cargos').doc(cargoId).collection('messages');

  CollectionReference<Map<String, dynamic>> _directMessages(
    String conversationId,
  ) =>
      _conversations.doc(conversationId).collection('messages');

  String directConversationId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }

  Stream<List<MessageModel>> watchMessages(String cargoId) {
    return _messages(cargoId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(MessageModel.fromFirestore).toList();
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.now();
        final bTime = b.timestamp ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<void> sendMessage(String cargoId, MessageModel message) async {
    await _messages(cargoId).add(message.toMap());
  }

  Stream<List<MessageModel>> watchDirectMessages(String conversationId) {
    return _directMessages(conversationId)
        .limit(200)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(MessageModel.fromFirestore).toList();
      // Sort newest-first so ListView(reverse:true) shows latest at bottom.
      list.sort((a, b) {
        final at = a.timestamp ?? DateTime(2000);
        final bt = b.timestamp ?? DateTime(2000);
        return bt.compareTo(at);
      });
      return list;
    });
  }


  Future<void> sendDirectMessage({
    required UserModel sender,
    required UserModel peer,
    String text = '',
    XFile? media,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && media == null) return;

    final authUid = AuthRepository.instance.currentUser?.uid;

    // Diagnostics
    assert(sender.uid.isNotEmpty, 'Sender UID must not be empty');
    assert(peer.uid.isNotEmpty, 'Peer UID must not be empty');
    assert(sender.uid != peer.uid, 'Cannot send message to self');
    assert(authUid == sender.uid, 'Auth UID mismatch');

    if (sender.uid.isEmpty || peer.uid.isEmpty) {
      throw Exception(
          'Ошибка: UID пользователя пуст (sender: ${sender.uid}, peer: ${peer.uid})');
    }
    if (authUid != sender.uid) {
      throw Exception(
          'Ошибка авторизации: текущий пользователь ($authUid) не совпадает с отправителем (${sender.uid})');
    }

    final conversationId = directConversationId(sender.uid, peer.uid);
    String? mediaUrl;
    String? mediaType;
    String? mediaName;

    if (media != null) {
      mediaName = _safeFileName(media.name);
      mediaType = media.mimeType ?? _guessMimeType(mediaName);
      final bytes = await media.readAsBytes();
      final storageRef = _storage.ref().child(
            'direct_chats/$conversationId/${DateTime.now().millisecondsSinceEpoch}_$mediaName',
          );

      try {
        await storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: mediaType,
            customMetadata: {
              'senderId': sender.uid,
              'peerId': peer.uid,
              'conversationId': conversationId,
            },
          ),
        );
        mediaUrl = await storageRef.getDownloadURL();
      } catch (e) {
        debugPrint('FAILED to upload media: $e');
        rethrow;
      }
    }

    final displayText = trimmed.isNotEmpty ? trimmed : (mediaName ?? 'Медиа');
    final message = MessageModel(
      id: '',
      text: trimmed,
      senderId: sender.uid,
      senderName: '${sender.displayName} (${sender.displayUsername})',
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      mediaName: mediaName,
    );

    final conversationRef = _conversations.doc(conversationId);
    final messageRef = _directMessages(conversationId).doc();

    // 1. Update/Create Conversation
    try {
      await conversationRef.set(
        {
          'participants': [sender.uid, peer.uid],
          'participantNames': {
            sender.uid: sender.displayName,
            peer.uid: peer.displayName,
          },
          'participantUsernames': {
            sender.uid: sender.displayUsername,
            peer.uid: peer.displayUsername,
          },
          'lastMessage': displayText,
          'lastSenderId': sender.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FAILED to update conversation $conversationId: $e');
      rethrow;
    }

    // 2. Add Message
    try {
      final messageData = message.toMap();
      // Ensure senderId is exactly sender.uid
      messageData['senderId'] = sender.uid;
      await messageRef.set(messageData);
    } catch (e) {
      debugPrint('FAILED to add message to $conversationId: $e');
      rethrow;
    }

    // 3. Update/Create Site Notification
    try {
      final notifId = 'chat_${conversationId}_${peer.uid}';
      await _firestore.collection('siteNotifications').doc(notifId).set({
        'userId': peer.uid,
        'title': 'Новое сообщение',
        'body': '${sender.displayName}: $displayText',
        'type': 'chat',
        'relatedId': conversationId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FAILED to create site notification: $e');
      // We don't rethrow here because the message was already sent
    }
  }

  String _safeFileName(String value) {
    final name = value.trim().isEmpty ? 'media' : value.trim();
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _guessMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'image/jpeg';
  }
}
