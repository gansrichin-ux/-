import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime? timestamp;
  final String? mediaUrl;
  final String? mediaType;
  final String? mediaName;

  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.timestamp,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Пользователь',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      mediaName: data['mediaName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.now(),
      if (mediaUrl?.isNotEmpty == true) 'mediaUrl': mediaUrl,
      if (mediaType?.isNotEmpty == true) 'mediaType': mediaType,
      if (mediaName?.isNotEmpty == true) 'mediaName': mediaName,
    };
  }
}
