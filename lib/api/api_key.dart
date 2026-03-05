import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bfp_record_mapping/api/path_variables.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  final String baseUrl = '${ApiKeys.pathVariable}${ApiKeys.dbConn}'; //my wifi
  final String tableName;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? whereClause;
  final String? orderBy;
  final int? limit;
  final int timeoutSeconds;

  ApiPhp({
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
      // ignore: unrelated_type_equality_checks

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
      return {
        "success": false,
        "statusCode": 0,
        "message": "Connection failed (OS Error: Network is unreachable.",
        "error": "client_exception",
        "data": null,
      };
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

  static Future<Map<String, dynamic>> uploadEstablishmentDocument({
    required dynamic file,
    required int establishmentId,
    required String establishmentName,
    required String documentType, // 'fsic', 'cro', 'fca'
    String? expiryDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiKeys.pathVariable}${ApiKeys.saveChkList}');
      final request = http.MultipartRequest('POST', uri);

      late List<int> bytes;
      late String filename;
      late String mimeType;

      // Handle different input types
      if (file is FilePickerResult) {
        final pickedFile = file.files.single;
        bytes = pickedFile.bytes!;
        filename = pickedFile.name;
        mimeType = pickedFile.extension == 'pdf'
            ? 'application/pdf'
            : pickedFile.extension == 'docx'
            ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            : 'image/${pickedFile.extension}';
      } else if (file is String) {
        final fileObj = File(file);
        bytes = await fileObj.readAsBytes();
        filename = file.split('/').last;
        final ext = filename.split('.').last.toLowerCase();
        mimeType = ext == 'pdf'
            ? 'application/pdf'
            : ext == 'docx'
            ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            : 'image/$ext';
      } else {
        return {"success": false, "message": "Invalid file format"};
      }

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add required fields
      request.fields['establishment_id'] = establishmentId.toString();
      request.fields['establishment_name'] = establishmentName;
      request.fields['document_type'] = documentType;

      if (documentType == 'fsic' && expiryDate != null) {
        request.fields['expiry_date'] = expiryDate;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse JSON safely
      try {
        final body = json.decode(response.body);
        return {
          "success": body["success"] ?? false,
          "message": body["message"] ?? "Upload completed",
          "file_path": body["file_path"],
          "file_name": body["file_name"],
          "original_name": body["original_name"],
        };
      } catch (_) {
        // If server returns HTML (like PHP warnings), don't crash
        return {
          "success": false,
          "message":
              "Server returned invalid JSON. Check PHP errors or upload limits.",
          "raw": response.body,
        };
      }
    } catch (e) {
      return {"success": false, "message": "Upload error: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>?> uploadPngFile({
    required Uint8List signatureBytes,
    required String fileName,
  }) async {
    try {
      // Create multipart request
      var uri = Uri.parse(
        '${ApiKeys.pathVariable}${ApiKeys.uploadSignatureImg}',
      );
      var request = http.MultipartRequest('POST', uri);

      // Add the Uint8List directly as file
      request.files.add(
        http.MultipartFile.fromBytes(
          'signature',
          signatureBytes,
          filename: fileName,
          contentType: MediaType('image', 'png'),
        ),
      );

      // Add filename parameter
      request.fields['file_name'] = fileName;

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = json.decode(response.body);

      if (responseData['success']) {
        String signaturePath = responseData['file_path'];

        return {
          'success': true,
          'file_path': signaturePath,
          'file_name': fileName,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> deleteSignatureFile({
    String? filePath,
    String? fileName,
    int? userId,
    bool? isUpdate,
  }) async {
    try {
      // Prepare the request
      var uri = Uri.parse('${ApiKeys.pathVariable}${ApiKeys.delSignatureImg}');

      // Prepare the data
      Map<String, dynamic> requestData = {};

      if (filePath != null && filePath.isNotEmpty) {
        requestData['file_path'] = filePath;
      }
      if (fileName != null && fileName.isNotEmpty) {
        requestData['file_name'] = fileName;
      }
      if (userId != null) {
        requestData['user_id'] = userId;
      }
      if (isUpdate != null) {
        requestData['is_update'] = isUpdate;
      }

      // Make the request
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      // Parse response
      if (response.statusCode == 200) {
        try {
          var responseData = json.decode(response.body);
          return responseData;
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid JSON response',
            'rawResponse': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
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
    print("baseUrl $baseUrl");
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

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiKeys.pathVariable}${ApiKeys.login}');
    print("url $url");
    try {
      // Check internet connection first
      final internetCheck = await NetworkUtils.hasInternetConnection();
      if (!internetCheck["success"]) {
        return {
          "success": false,
          "message": "No internet connection",
          "error": "network_unavailable",
        };
      }

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'data': {'email': email, 'password': password},
            }),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              return http.Response(
                json.encode({
                  "success": false,
                  "message": "Connection timeout",
                }),
                408,
              );
            },
          );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['success'] == true) {
          return {
            "success": true,
            "message": body['message'] ?? "Login successful",
            "data": body['data'],
          };
        } else {
          return {
            "success": false,
            "message": body['message'] ?? "Login failed",
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Login error: ${e.toString()}"};
    }
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
