import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class PayloadCryptoHelper {

  static final _key = encrypt.Key.fromUtf8('BlueMeshSecureKey32BytesLong!!!');
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static Uint8List encryptPayload(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final encrypted = _encrypter.encrypt(jsonString, iv: _iv);
    return encrypted.bytes;
  }

  static Map<String, dynamic> decryptPayload(Uint8List encryptedBytes) {
    final encrypted = encrypt.Encrypted(encryptedBytes);
    final decryptedString = _encrypter.decrypt(encrypted, iv: _iv);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }
}