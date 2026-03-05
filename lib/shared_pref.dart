import 'dart:convert';
import 'dart:typed_data';

import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:bfp_record_mapping/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreCredentials {
  // //encrypt data
  // static Future<void> encryptData(String plaintText, String key) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String skey = ApiKeys.encryptionKey;

  //   Uint8List aesKey = Encryption.generateKey(skey, 16);
  //   final nonce = Encryption.generateRandomNonce();

  //   final encrypted = await Encryption.encrypt(
  //     aesKey,
  //     nonce,
  //     json.encode(plaintText),
  //   );

  //   final concatenatedArray = Encryption.concatBuffers(nonce, encrypted);
  //   final output = Encryption.arrayBufferToBase64(concatenatedArray);

  //   prefs.setString(key, output);
  // }

  // static Future<dynamic> getEncryptedKeys(String key) async {
  //   String hash = "";
  //   String skey = ApiKeys.encryptionKey;
  //   final prefs = await SharedPreferences.getInstance();
  //   final output = prefs.getString(key);

  //   if (output != null) {
  //     hash = Uri.encodeComponent(output);

  //     Uint8List aesKey = Encryption.generateKey(skey, 16);

  //     final encryptedData = base64Decode(Uri.decodeComponent(hash));

  //     final nonces = encryptedData.sublist(0, 16);

  //     final cipherText = encryptedData.sublist(16);

  //     final decryptedData = Encryption.decrypt(aesKey, nonces, cipherText);
  //     print("decryptedData $decryptedData");
  //     final data = utf8.decode(decryptedData as List<int>);
  //     final dataList = await jsonDecode(data);

  //     return jsonDecode(dataList);
  //   } else {
  //     return null;
  //   }
  // }

  //encrypt data
  Future<void> encryptData(String plaintText, String uniqueKey) async {
    final prefs = await SharedPreferences.getInstance();
    String skey = ApiKeys.encryptionKey;

    String inatayaaa = jsonEncode(skey);
    Uint8List aesKey = Functions.generateKey(inatayaaa, 16);
    final nonce = Functions.generateRandomNonce();

    final encrypted = await Functions.encryptData(
      aesKey,
      nonce,
      json.encode(plaintText),
    );

    final concatenatedArray = Functions.concatBuffers(nonce, encrypted);
    final output = Functions.arrayBufferToBase64(concatenatedArray);

    prefs.setString(uniqueKey, output);
  }

  Future<dynamic> getEncryptedKeys(String uniqueKey) async {
    String hash = "";
    String skey = ApiKeys.encryptionKey;
    final prefs = await SharedPreferences.getInstance();
    final output = prefs.getString(uniqueKey);

    if (output != null) {
      hash = Uri.encodeComponent(output);
      String inatayaaa = jsonEncode(skey);
      Uint8List aesKey = Functions.generateKey(inatayaaa, 16);

      final encryptedData = base64Decode(Uri.decodeComponent(hash));

      final nonces = encryptedData.sublist(0, 16);

      final cipherText = encryptedData.sublist(16);

      final decryptedData = await Functions().decryptData(
        aesKey,
        nonces,
        cipherText,
      );
      final data = utf8.decode(decryptedData);
      final dataList = await jsonDecode(data);

      return jsonDecode(dataList);
    } else {
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> sessionData) async {
    await encryptData(jsonEncode(sessionData), "user_data");
  }

  Future<dynamic> getUserData() async {
    return getEncryptedKeys("user_data");
  }
}
