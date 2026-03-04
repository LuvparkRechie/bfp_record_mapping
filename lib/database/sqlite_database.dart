import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inspection.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5, // Increment to version 3 for signatures table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Create inspection_reports table
    await db.execute('''
      CREATE TABLE inspection_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_no TEXT UNIQUE,
        building_name TEXT,
        building_address TEXT,
        inspector_name TEXT,
        inspection_date TEXT,
        submission_date TEXT,
        status TEXT,
        total_items INTEGER,
        passed_items INTEGER,
        failed_items INTEGER,
        na_items INTEGER,
        overall_status TEXT,
        notes TEXT,
        answers TEXT,
        owner_signature_path TEXT,
        inspector_signature TEXT,
        establishment_id INTEGER,
        inspector_id INTEGER,
        inspection_id INTEGER,
        latitude REAL,
        longitude REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create signatures table for storing signature bytes and filename
    await db.execute('''
      CREATE TABLE signatures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        establishment_id INTEGER ,
        report_no TEXT,
        signature_bytes BLOB,
        file_name TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (report_no) REFERENCES inspection_reports (report_no) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add inspection_reports table when upgrading from version 1 to 2
      await db.execute('''
        CREATE TABLE inspection_reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          report_no TEXT UNIQUE,
          building_name TEXT,
          building_address TEXT,
          inspector_name TEXT,
          inspection_date TEXT,
          submission_date TEXT,
          status TEXT,
          total_items INTEGER,
          passed_items INTEGER,
          failed_items INTEGER,
          na_items INTEGER,
          overall_status TEXT,
          notes TEXT,
          answers TEXT,
          owner_signature_path TEXT,
          inspector_signature TEXT,
          establishment_id INTEGER,
          inspector_id INTEGER,
          inspection_id INTEGER,
          latitude REAL,
          longitude REAL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          synced INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add signatures table when upgrading from version 2 to 3
      await db.execute('''
        CREATE TABLE signatures (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          establishment_id INTEGER ,
          report_no TEXT,
          signature_bytes BLOB,
          file_name TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (report_no) REFERENCES inspection_reports (report_no) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ==================== INSPECTION REPORTS METHODS ====================

  // Insert a new inspection report
  Future<int> insertInspectionReport(Map<String, dynamic> reportData) async {
    final db = await instance.database;

    // Add synced flag (0 = not synced, 1 = synced)
    reportData['synced'] = 0;

    return await db.insert(
      'inspection_reports',
      reportData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all inspection reports
  Future<List<Map<String, dynamic>>> getAllInspectionReports() async {
    final db = await instance.database;
    return await db.query('inspection_reports', orderBy: 'created_at DESC');
  }

  // Get a single inspection report by report_no
  Future<Map<String, dynamic>?> getInspectionReport(String reportNo) async {
    final db = await instance.database;
    final results = await db.query(
      'inspection_reports',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Get reports by establishment ID
  Future<List<Map<String, dynamic>>> getReportsByEstablishment(
    int establishmentId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'inspection_reports',
      where: 'establishment_id = ?',
      whereArgs: [establishmentId],
      orderBy: 'created_at DESC',
    );
  }

  // Get reports by inspector ID
  Future<List<Map<String, dynamic>>> getReportsByInspector(
    int inspectorId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'inspection_reports',
      where: 'inspector_id = ?',
      whereArgs: [inspectorId],
      orderBy: 'created_at DESC',
    );
  }

  // Get reports by status
  Future<List<Map<String, dynamic>>> getReportsByStatus(String status) async {
    final db = await instance.database;
    return await db.query(
      'inspection_reports',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  // Get unsynced reports
  Future<List<Map<String, dynamic>>> getUnsyncedReports() async {
    final db = await instance.database;
    return await db.query(
      'inspection_reports',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  // Update an inspection report
  Future<int> updateInspectionReport(
    String reportNo,
    Map<String, dynamic> updates,
  ) async {
    final db = await instance.database;
    return await db.update(
      'inspection_reports',
      updates,
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
  }

  // Mark report as synced
  Future<int> markReportAsSynced(String reportNo) async {
    final db = await instance.database;
    return await db.update(
      'inspection_reports',
      {'synced': 1},
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
  }

  // Delete an inspection report
  Future<int> deleteInspectionReport(String reportNo) async {
    final db = await instance.database;
    return await db.delete(
      'inspection_reports',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
  }

  // Delete all synced reports
  Future<int> deleteAllSyncedReports() async {
    final db = await instance.database;
    return await db.delete('inspection_reports', where: 'synced = 1');
  }

  // Get report count
  Future<int> getReportCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM inspection_reports');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get reports by date range
  Future<List<Map<String, dynamic>>> getReportsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await instance.database;
    return await db.query(
      'inspection_reports',
      where: 'inspection_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'inspection_date DESC',
    );
  }

  // ==================== SIGNATURE METHODS ====================

  // Insert signature
  Future<int> insertSignature({
    required String reportNo,
    required Uint8List signatureBytes,
    required String fileName,
    required int id,
  }) async {
    final db = await instance.database;

    final data = {
      'report_no': reportNo,
      'signature_bytes': signatureBytes,
      'file_name': fileName,
      'establishment_id': id,
    };

    return await db.insert('signatures', data);
  }

  // Get signature by report number
  Future<Map<String, dynamic>?> getSignature(String reportNo) async {
    final db = await instance.database;
    final results = await db.query(
      'signatures',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );

    return results.isNotEmpty ? results.first : null;
  }

  // Get signature bytes only
  Future<Uint8List?> getSignatureBytes(String reportNo) async {
    final db = await instance.database;
    final results = await db.query(
      'signatures',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );

    if (results.isNotEmpty && results.first['signature_bytes'] != null) {
      return results.first['signature_bytes'] as Uint8List;
    }
    return null;
  }

  // Get file name only
  Future<String?> getSignatureFileName(String reportNo) async {
    final db = await instance.database;
    final results = await db.query(
      'signatures',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );

    if (results.isNotEmpty) {
      return results.first['file_name'] as String?;
    }
    return null;
  }

  // Update signature
  Future<int> updateSignature({
    required String reportNo,
    required Uint8List signatureBytes,
    required String fileName,
  }) async {
    final db = await instance.database;

    return await db.update(
      'signatures',
      {'signature_bytes': signatureBytes, 'file_name': fileName},
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
  }

  // Delete signature
  Future<int> deleteSignature(String reportNo) async {
    final db = await instance.database;
    return await db.delete(
      'signatures',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
  }

  // Check if signature exists for a report
  Future<bool> signatureExists(String reportNo) async {
    final db = await instance.database;
    final results = await db.query(
      'signatures',
      where: 'report_no = ?',
      whereArgs: [reportNo],
    );
    return results.isNotEmpty;
  }

  // Get all tasks
  Future<List<Map<String, dynamic>>> getAllSignature() async {
    final db = await instance.database;
    return await db.query('signatures', where: "1=1");
  }

  // Delete all synced reports
  Future<int> deleteAllSignatures() async {
    final db = await instance.database;
    return await db.delete('signatures', where: '1 = 1');
  }
}
