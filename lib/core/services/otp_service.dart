import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Stores and validates 6-digit OTP codes in Firestore.
/// Sends codes via Resend email API.
class OtpService {
  OtpService._();
  static final OtpService instance = OtpService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Config ─────────────────────────────────────────────────────────
  static const _expiryMinutes = 10;

  // ── Generate, store & send ────────────────────────────────────────────────

  /// Generates a 6-digit code, saves in Firestore, sends via Resend.
  /// Returns null on success, or an error string.
  Future<String?> sendCode(String uid, String toEmail) async {
    try {
      final code = _randomCode();

      await _db.collection('emailOtpCodes').doc(uid).set({
        'code': code,
        'uid': uid,
        'email': toEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: _expiryMinutes)),
        ),
        'used': false,
      });

      return await _sendEmail(toEmail: toEmail, code: code);
    } catch (e) {
      return 'Ошибка генерации кода: $e';
    }
  }

  // ── Validate ──────────────────────────────────────────────────────────────

  /// Returns null on success, or a human-readable error string.
  Future<String?> verifyCode(String uid, String enteredCode) async {
    try {
      final doc = await _db.collection('emailOtpCodes').doc(uid).get();
      if (!doc.exists) return 'Код не найден. Запросите новый.';

      final data = doc.data()!;
      if (data['used'] == true) return 'Код уже использован. Запросите новый.';

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        return 'Срок действия кода истёк. Запросите новый.';
      }

      if (data['code'] != enteredCode.trim()) return 'Неверный код.';

      // Mark code as used
      await doc.reference.update({'used': true});

      // Mark user as verified in Firestore
      await _db.collection('users').doc(uid).set(
        {'emailCodeVerified': true},
        SetOptions(merge: true),
      );

      return null; // success
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  // ── Cloud Function Call ──────────────────────────────────────────────────────

  Future<String?> _sendEmail(
      {required String toEmail, required String code}) async {
    try {
      final url = Uri.parse(
          'https://us-central1-logist-app-55ac9.cloudfunctions.net/sendOtpEmail');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'email': toEmail,
            'code': code,
          }
        }),
      );

      if (response.statusCode == 200) {
        return null; // success
      } else {
        return 'Ошибка сервера: ${response.statusCode}';
      }
    } catch (e) {
      // Network error or function error
      return 'Ошибка отправки Cloud Function: $e';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _randomCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
