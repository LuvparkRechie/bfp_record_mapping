import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pointycastle/export.dart' as crypto;
import 'package:url_launcher/url_launcher.dart';

class Functions {
  static Future<Position?> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static void viewOnMap(Map<String, dynamic> coordinates, context) async {
    final result = await getLocation();

    if (result == null) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final String url =
        "https://www.google.com/maps/dir/?api=1&origin=${result.latitude},${result.longitude}&destination=${coordinates['latitude']},${coordinates['longitude']}&travelmode=driving";

    final Uri uri = Uri.parse(url);
    Navigator.of(context).pop();

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // distance in meters
  }

  static double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  // i used this to generate unique secret key
  static Uint8List generateKey(String key, int length) {
    var keyBytes = utf8.encode(key);
    if (keyBytes.length < length) {
      keyBytes = Uint8List.fromList([
        ...keyBytes,
        ...List.filled(length - keyBytes.length, 0),
      ]);
    } else if (keyBytes.length > length) {
      keyBytes = keyBytes.sublist(0, length);
    }
    return Uint8List.fromList(keyBytes);
  }

  static Uint8List generateRandomNonce() {
    var random = Random.secure();
    var iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  static Future<Uint8List> encryptData(
    Uint8List secretKey,
    Uint8List iv,
    String plainText,
  ) async {
    final cipher = crypto.GCMBlockCipher(crypto.AESFastEngine());

    final keyParams = crypto.KeyParameter(secretKey);
    final cipherParams = crypto.ParametersWithIV(keyParams, iv);
    cipher.init(true, cipherParams);

    final encodedPlainText = utf8.encode(plainText);
    final cipherText = cipher.process(Uint8List.fromList(encodedPlainText));

    return Uint8List.fromList(cipherText);
  }

  static ByteBuffer concatBuffers(Uint8List buffer1, Uint8List buffer2) {
    final tmp = Uint8List(buffer1.length + buffer2.length);
    tmp.setAll(0, buffer1);
    tmp.setAll(buffer1.length, buffer2);
    return tmp.buffer;
  }

  static String arrayBufferToBase64(ByteBuffer buffer) {
    var bytes = Uint8List.view(buffer);
    var base64String = base64.encode(bytes);
    return base64String;
  }

  Future<Uint8List> decryptData(
    Uint8List secretKey,
    Uint8List nonce,
    Uint8List cipherText,
  ) async {
    final cipher = crypto.GCMBlockCipher(crypto.AESFastEngine());

    final keyParams = crypto.KeyParameter(secretKey);
    final cipherParams = crypto.ParametersWithIV(keyParams, nonce);
    cipher.init(false, cipherParams);

    final plainTextBytes = cipher.process(cipherText);

    return Uint8List.fromList(plainTextBytes);
  }
}
