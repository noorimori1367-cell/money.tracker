import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'finance.dart';

class Store {
  final Database db;
  Store(this.db);
  static Future<Store> open() async {
    sqfliteFfiInit();
    final folder = await getApplicationSupportDirectory();
    await folder.create(recursive: true);
    final db = await databaseFactoryFfi.openDatabase(
      '${folder.path}${Platform.pathSeparator}sahm.sqlite',
      options: OpenDatabaseOptions(version: 1, onCreate: (d, _) async {
        await d.execute('CREATE TABLE trades(id TEXT PRIMARY KEY, asset TEXT, side TEXT, qty TEXT, price TEXT, fx TEXT, currency TEXT, fee TEXT, day INTEGER, note TEXT, updated TEXT, deleted INTEGER DEFAULT 0)');
        await d.execute('CREATE TABLE quotes(id TEXT PRIMARY KEY,asset TEXT,price TEXT,fx TEXT,currency TEXT,updated TEXT)');
      }));
    return Store(db);
  }
  Future<List<RowData>> trades(DatabaseExecutor d) => d.query('trades',where:'deleted=0',orderBy:'day,rowid');
  Future<void> save(RowData row) => db.transaction((tx) async {
    if (await tx.update('trades',row,where:'id=?',whereArgs:[row['id']]) == 0) await tx.insert('trades',row);
    replay(await trades(tx)); // Reject edits that invalidate a later sale.
  });
}
