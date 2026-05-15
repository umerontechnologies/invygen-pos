import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class BackupService {
  static const tables = [
    'businesses', 'profiles', 'categories', 'suppliers', 'products', 'customers', 'retailer_prices',
    'purchases', 'purchase_items', 'sales', 'sale_items', 'orders', 'order_items', 'payments',
    'expenses', 'stock_movements', 'app_settings'
  ];

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<File> exportJsonFile() async {
    final db = await _db;
    final data = <String, dynamic>{'app': 'Invygen', 'version': 1, 'exported_at': DateTime.now().toIso8601String(), 'tables': {}};
    for (final table in tables) {
      data['tables'][table] = await db.query(table);
    }
    final dir = await getApplicationDocumentsDirectory();
    final name = 'invygen_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<void> shareBackup() async {
    final file = await exportJsonFile();
    await Share.shareXFiles([XFile(file.path)], text: 'Invygen backup');
  }

  Future<int> restoreFromPickedFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return 0;
    final file = File(result.files.single.path!);
    final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final tablesData = decoded['tables'] as Map<String, dynamic>;
    final db = await _db;
    var imported = 0;
    await db.transaction((txn) async {
      for (final table in tables.reversed) {
        await txn.delete(table);
      }
      for (final table in tables) {
        final rows = (tablesData[table] as List?) ?? [];
        for (final raw in rows) {
          await txn.insert(table, Map<String, dynamic>.from(raw as Map), conflictAlgorithm: ConflictAlgorithm.replace);
          imported++;
        }
      }
    });
    return imported;
  }
}
