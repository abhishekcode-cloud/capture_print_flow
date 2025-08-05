import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/image_model.dart';
import '../model/logo_model.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'image_overlay.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            status TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE logo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT
          )
        ''');
      },
    );
  }

  // ---------------- IMAGE FUNCTIONS ----------------

  Future<int> insertImage(ImageModel img) async {
    final db = await database;
    return await db.insert('images', img.toMap());
  }

  Future<int> updateImage(ImageModel img) async {
    final db = await database;
    return await db.update(
      'images',
      img.toMap(),
      where: 'id = ?',
      whereArgs: [img.id],
    );
  }

  Future<ImageModel?> getImage(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'images',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? ImageModel.fromMap(result.first) : null;
  }

  Future<List<ImageModel>> fetchImages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('images');
    return maps.map((map) => ImageModel.fromMap(map)).toList();
  }

  Future<int> deleteImage(int id) async {
    final db = await database;
    return await db.delete('images', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- LOGO FUNCTIONS ----------------

  Future<void> insertLogo(LogoModel logo) async {
    final db = await database;
    await db.delete('logo'); // Only allow one logo at a time
    await db.insert('logo', logo.toMap());
  }

  Future<LogoModel?> getLogo() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query('logo');
    return result.isNotEmpty ? LogoModel.fromMap(result.first) : null;
  }

  Future<void> deleteLogo(int id) async {
    final db = await database;
    await db.delete('logo', where: 'id = ?', whereArgs: [id]);
  }
}
