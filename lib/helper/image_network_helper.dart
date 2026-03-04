import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageHelper {
  static String baseUrl = 'http://192.168.11.150';

  // Load image via JSON + Base64 (most reliable for Flutter Web)
  static Future<Uint8List?> loadImageViaJson(String filename) async {
    String url = 'http://192.168.11.150/mapping/get_img.php?file=$filename';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          String base64Data = jsonData['data'];

          // Decode base64 to bytes
          Uint8List imageBytes = base64.decode(base64Data);

          return imageBytes;
        } else {}
      } else {}
    } catch (e) {
      print('❌ Error loading via JSON: $e');
    }
    return null;
  }

  // Build signature image widget
  static Widget buildSignatureImage({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholder('No signature', width, height);
    }

    String filename = imagePath.split('/').last;

    return FutureBuilder<Uint8List?>(
      future: loadImageViaJson(filename),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(width, height);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image.memory error: $error');
              return _buildPlaceholder('Invalid image data', width, height);
            },
          );
        }

        return _buildPlaceholder('Failed to load\n$filename', width, height);
      },
    );
  }

  static Widget _buildLoadingIndicator(double? width, double? height) {
    return Container(
      width: width,
      height: height ?? 100,
      color: Colors.grey[100],
      child: Center(child: CircularProgressIndicator()),
    );
  }

  static Widget _buildPlaceholder(
    String message,
    double? width,
    double? height,
  ) {
    return Container(
      width: width,
      height: height ?? 100,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[600]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Debug helper
class SignatureDebugger {
  static Future<void> debugSignature(String? imagePath) async {
    if (imagePath == null) {
      print('❌ No image path');
      return;
    }

    String filename = imagePath.split('/').last;

    String url =
        'http://192.168.11.150/mapping/get_image_json.php?file=$filename';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
        } else {}
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}
