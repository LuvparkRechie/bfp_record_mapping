import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<dynamic> getAddressFromLatLngOSM(double lat, double lon) async {
  final url =
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=$lat'
      '&lon=$lon'
      '&zoom=18'
      '&addressdetails=1';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent': 'hnhs_emergency_response', // REQUIRED
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    return {
      "data": data,
      "message": data['display_name'] == null ? 'Address not found' : "",
    };
  }
  return 'Address not found';
}

class ApiPhp {
  final String baseUrl = 'https://luvpark.ph/luvtest/mapping/api.php';
  final String tableName;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? whereClause;
  final String? orderBy;
  final int? limit;
  final int timeoutSeconds;

  const ApiPhp({
    required this.tableName,
    this.parameters,
    this.whereClause,
    this.orderBy,
    this.limit,
    this.timeoutSeconds = 20,
  });

  Future<Map<String, dynamic>> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return {
          "success": false,
          "statusCode": 0,
          "message": "No internet connection",
          "error": "network_unavailable",
          "data": null,
        };
      }
      return {"success": true};
    } catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "message": "Connection check failed",
        "error": "connectivity_check_failed",
        "data": null,
      };
    }
  }

  // -------------------------------
  // PARSE RESPONSE
  // -------------------------------
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = json.decode(response.body);

      bool isSuccess =
          response.statusCode == 200 &&
          (data["status"] == "success" || data["success"] == true);

      return {
        "success": isSuccess,
        "statusCode": response.statusCode,
        "message": data["message"] ?? "",
        "data": data.containsKey("data") ? data["data"] : null,
        "id": data["id"],
        "error": data["error"],
        "rawBody": response.body,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": response.statusCode,
        "message": "Invalid JSON response: ${e.toString()}",
        "error": "json_parse_error",
        "rawBody": response.body,
      };
    }
  }

  // -------------------------------
  // HANDLE NETWORK REQUEST WITH TIMEOUT
  // -------------------------------
  Future<Map<String, dynamic>> _handleRequest(
    Future<http.Response> request,
  ) async {
    // Check internet connection first
    final internetCheck = await _checkInternetConnection();
    if (!internetCheck["success"]) {
      return internetCheck;
    }

    try {
      final response = await request.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          return http.Response(
            json.encode({
              "success": false,
              "message": "Request timeout after ${timeoutSeconds}s",
              "error": "timeout",
            }),
            408,
          );
        },
      );

      return _parseResponse(response);
    } on http.ClientException catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "message": "Network error: ${e.message}",
        "error": "client_exception",
        "data": null,
      };
    } on FormatException catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "message": "Data format error: ${e.message}",
        "error": "format_exception",
        "data": null,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "message": "Unexpected error: ${e.toString()}",
        "error": "unknown_error",
        "data": null,
      };
    }
  }

  // -------------------------------
  // INSERT operation
  // -------------------------------
  Future<Map<String, dynamic>> insert({subUrl, jsonParam}) async {
    return await _handleRequest(
      http.post(
        Uri.parse(subUrl ?? baseUrl),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonParam ??
            json.encode({
              'table': tableName,
              'operation': 'insert',
              'data': parameters ?? {},
            }),
      ),
    );
  }

  // In your ApiPhp class, add:
  Future<Map<String, dynamic>> finishReport(Map<String, dynamic> data) async {
    return await _handleRequest(
      http.post(
        Uri.parse("https://luvpark.ph/luvtest/bfp_finish_reports.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ),
    );
  }

  Future<Map<String, dynamic>> insertAdminAlert() async {
    String alertUrl = "https://luvpark.ph/luvtest/admin_alert.php";
    return await _handleRequest(
      http.post(
        Uri.parse(alertUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'insert',
          'data': parameters ?? {},
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> insertMood() async {
    String alertUrl = "https://luvpark.ph/luvtest/mood_entry.php";
    return await _handleRequest(
      http.post(
        Uri.parse(alertUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'insert',
          'data': parameters ?? {},
        }),
      ),
    );
  }

  // -------------------------------
  // UPDATE operation
  // -------------------------------
  Future<Map<String, dynamic>> update({subUrl}) async {
    return await _handleRequest(
      http.post(
        Uri.parse(subUrl ?? baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'update',
          'data': parameters ?? {},
          'where': whereClause ?? {},
        }),
      ),
    );
  }

  // -------------------------------
  // DELETE operation
  // -------------------------------
  Future<Map<String, dynamic>> delete() async {
    return await _handleRequest(
      http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'delete',
          'where': whereClause ?? {},
        }),
      ),
    );
  }

  // -------------------------------
  // SELECT operation (UPDATED with orderBy and limit)
  // -------------------------------
  Future<Map<String, dynamic>> select({subURl}) async {
    return await _handleRequest(
      http.post(
        Uri.parse(subURl ?? baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'select',
          'where': whereClause ?? {},
          'orderBy': orderBy,
          'limit': limit,
        }),
      ),
    );
  }

  // -------------------------------
  // SELECT with columns (UPDATED with orderBy and limit)
  // -------------------------------
  Future<Map<String, dynamic>> selectColumns(List<String> columns) async {
    return await _handleRequest(
      http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'select',
          'columns': columns,
          'where': whereClause ?? {},
          'orderBy': orderBy,
          'limit': limit,
        }),
      ),
    );
  }

  // -------------------------------
  // BATCH INSERT operation
  // -------------------------------
  Future<Map<String, dynamic>> batchInsert(
    List<Map<String, dynamic>> records,
  ) async {
    return await _handleRequest(
      http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'batch_insert',
          'data': records,
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> submitReportWithImage({
    required XFile image,
  }) async {
    final uri = Uri.parse(
      "https://luvpark.ph/luvtest/bfp_incident_reports.php",
    );

    var request = http.MultipartRequest('POST', uri);

    // Add the image
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    // Add report fields as text
    parameters!.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          "success": body["success"],
          "message": body["message"] ?? "Report submitted successfully",
          "data": body["data"],
        };
      } else {
        return {
          "success": false,
          "message": "Submission failed with status: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Submission error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> uploadEstablishmentDocument({
    required dynamic file, // Can be String path or FilePickerResult
    required int establishmentId,
    required String documentType,
    String? expiryDate,
  }) async {
    final uri = Uri.parse("https://luvpark.ph/luvtest/mapping/upload_file.php");

    var request = http.MultipartRequest('POST', uri);

    late List<int> bytes;
    late String filename;

    // Handle different input types
    if (file is FilePickerResult) {
      // Web: Use bytes directly from FilePickerResult
      final pickedFile = file.files.single;
      bytes = pickedFile.bytes!;
      filename = pickedFile.name;
    } else if (file is String) {
      // Mobile: Read from file path
      final fileObj = File(file);
      bytes = await fileObj.readAsBytes();
      filename = file.split('/').last;
    } else {
      return {"success": false, "message": "Invalid file format"};
    }

    // Add file using fromBytes (works on web)
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: http.MediaType('application', 'octet-stream'),
      ),
    );

    // Add fields
    request.fields['establishment_id'] = establishmentId.toString();
    request.fields['document_type'] = documentType;

    // Only add expiry_date for FSIC and if provided
    if (documentType == 'fsic' && expiryDate != null) {
      request.fields['expiry_date'] = expiryDate;
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return {
          "success": body["success"],
          "message": body["message"] ?? "Upload successful",
          "file_path": body["file_path"],
          "file_name": body["file_name"],
        };
      } else {
        return {
          "success": false,
          "message": "Upload failed with status: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Upload error: ${e.toString()}"};
    }
  }

  // -------------------------------
  // COUNT operation (UPDATED with orderBy and limit)
  // -------------------------------
  Future<Map<String, dynamic>> count() async {
    return await _handleRequest(
      http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'count',
          'where': whereClause ?? {},
          'orderBy': orderBy,
          'limit': limit,
        }),
      ),
    );
  }

  // -------------------------------
  // Select with join (UPDATED with orderBy and limit)
  // -------------------------------
  Future<Map<String, dynamic>> selectWithJoin(
    Map<String, dynamic> joinConfig,
  ) async {
    // Merge the joinConfig with orderBy and limit
    final mergedJoinConfig = Map<String, dynamic>.from(joinConfig);

    if (orderBy != null) {
      mergedJoinConfig['orderBy'] = orderBy;
    }

    if (limit != null) {
      mergedJoinConfig['limit'] = limit;
    }

    return await _handleRequest(
      http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'table': tableName,
          'operation': 'select_with_join',
          'join_config': mergedJoinConfig,
        }),
      ),
    );
  }

  // -------------------------------
  // PING INTERNET
  // -------------------------------
  static Future<Map<String, dynamic>> pingInternet() async {
    try {
      final response = await http
          .get(Uri.parse("https://www.google.com/"))
          .timeout(const Duration(seconds: 10));

      return {
        "success": response.statusCode == 200,
        "statusCode": response.statusCode,
        "message": response.statusCode == 200
            ? "Internet available"
            : "Internet check failed",
        "data": null,
      };
    } catch (e) {
      return {
        "success": false,
        "statusCode": 0,
        "message": "No internet connection",
        "error": "ping_failed",
        "data": null,
      };
    }
  }

  Future<List<String>> fetchReportImages(int reportId) async {
    final url =
        'https://luvpark.ph/luvtest/bfp_get_img_uploads.php?report_id=$reportId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      if (body['success'] == true) {
        return (body['data'] as List)
            .map<String>((img) => img['image_url'] as String)
            .toList();
      }
    }
    return [];
  }
}

// -------------------------------
// CONNECTIVITY HELPER CLASS
// -------------------------------
class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  // Check if device has internet connection
  static Future<Map<String, dynamic>> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;

      return {
        "success": hasConnection,
        "message": hasConnection ? "Connected" : "No internet connection",
        "connectionType": result.toString(),
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Connection check failed: ${e.toString()}",
        "error": "connectivity_error",
      };
    }
  }

  // Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  // Check with timeout
  static Future<Map<String, dynamic>> hasInternetWithTimeout([
    Duration timeout = const Duration(seconds: 5),
  ]) async {
    try {
      final result = await hasInternetConnection().timeout(timeout);
      return result;
    } on TimeoutException {
      return {
        "success": false,
        "message": "Connection check timeout",
        "error": "timeout",
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Connection check failed: ${e.toString()}",
        "error": "unknown_error",
      };
    }
  }
}
