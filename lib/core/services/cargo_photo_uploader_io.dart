import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadCargoPhoto(Reference ref, Object file) async {
  if (file is! File) {
    throw ArgumentError('Expected dart:io File for photo upload');
  }

  await ref.putFile(file);
  return ref.getDownloadURL();
}
