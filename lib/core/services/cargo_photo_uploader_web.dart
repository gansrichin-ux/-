import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadCargoPhoto(Reference ref, Object file) async {
  if (file is! Uint8List) {
    throw ArgumentError('Web photo upload expects Uint8List but got ${file.runtimeType}');
  }

  final metadata = SettableMetadata(
    contentType: 'image/jpeg',
    cacheControl: 'public,max-age=3600',
  );

  final uploadTask = ref.putData(file, metadata);
  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}
