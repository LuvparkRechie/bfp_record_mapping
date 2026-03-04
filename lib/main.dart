import 'dart:async';
import 'dart:convert';

import 'package:bfp_record_mapping/api/api_key.dart';
import 'package:bfp_record_mapping/database/sqlite_database.dart';
import 'package:bfp_record_mapping/screens/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> backgroundFunc() async {
  Timer.periodic((Duration(minutes: 5)), (d) async {
    revertSchedData();
  });
  Timer.periodic((Duration(minutes: 1)), (d) async {
    storeLocalData();
  });
}

void revertSchedData() async {
  try {
    // Revert to admin after scheduled date
    await ApiPhp(tableName: "", parameters: {}).insert(
      subUrl: 'http://192.168.11.150/mapping/job.php',
      jsonParam: json.encode({
        "data": {"current_date": DateTime.now().toIso8601String()},
      }),
    );
  } catch (e) {
    print("cathce $e");
  }
}

void storeLocalData() async {
  final dbHelper = DatabaseHelper.instance;
  final reportData = await dbHelper.getAllInspectionReports();
  final signatureData = await dbHelper.getAllSignature();

  print("reportData $reportData");
  print("signatureData $signatureData");

  try {
    if (signatureData.isNotEmpty) {
      final uploadResult = await ApiPhp.uploadPngFile(
        signatureBytes: signatureData[0]["signature_bytes"]!,
        fileName: signatureData[0]["file_name"]!,
      );
      print("uploadResult $uploadResult");
      if (!uploadResult!["success"]) {
        return;
      }
      await dbHelper.deleteSignature(signatureData[0]["report_no"].toString());
    }
    if (reportData.isNotEmpty) {
      final response = await ApiPhp(
        tableName: "inspection_reports",
        parameters: reportData[0],
      ).insert(subUrl: 'http://192.168.11.150/mapping/save_checklist.php');
      print("response $response");
      if (response["success"]) {
        await dbHelper.deleteInspectionReport(reportData[0]["id"]);
        await Future.delayed(Duration(seconds: 3));

        print("success storing inspection");
        storeLocalData();
      } else {
        print("sElse walan");
      }
    }
  } catch (e) {
    rethrow;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async DB init

  DatabaseHelper.instance;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      backgroundFunc();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Safety Checklist',
      theme: ThemeData(primarySwatch: Colors.red),
      home: SplashScreen(),
    );
  }
}
