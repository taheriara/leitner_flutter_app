// // db_helper.dart

// import 'dart:io';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import '../data/models/flashcard_model.dart';

// class DBHelper {
//   DBHelper._privateConstructor();
//   static final DBHelper instance = DBHelper._privateConstructor();

//   Database? _db;

//   Future<void> init() async {
//     if (_db != null) return;

//     Directory docsDir = await getApplicationDocumentsDirectory();
//     String path = p.join(docsDir.path, 'leitner.db');

//     _db = await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE cards (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             english TEXT NOT NULL,
//             persian TEXT NOT NULL,
//             box INTEGER NOT NULL,
//             lastReviewed INTEGER NOT NULL
//           );
//         ''');
//       },
//     );
//   }

//   Future<int> insertCard(FlashCardModel card) async {
//     return await _db!.insert('cards', card.toMap());
//   }

//   Future<int> updateCard(FlashCardModel card) async {
//     return await _db!.update(
//       'cards',
//       card.toMap(),
//       where: 'id = ?',
//       whereArgs: [card.id],
//     );
//   }

//   Future<int> deleteCard(int id) async {
//     return await _db!.delete('cards', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<List<FlashCardModel>> allCards() async {
//     final rows = await _db!.query('cards');
//     return rows.map((e) => FlashCardModel.fromMap(e)).toList();
//   }

//   Future<List<FlashCardModel>> cardsByBox(int box) async {
//     final rows = await _db!.query('cards', where: 'box = ?', whereArgs: [box]);
//     return rows.map((e) => FlashCardModel.fromMap(e)).toList();
//   }

//   // کارت‌های آماده برای مرور در روز جاری مطابق لایتنر
//   Future<List<FlashCardModel>> dueCards() async {
//     final rows = await _db!.query('cards');
//     List<FlashCardModel> allCards = rows
//         .map((e) => FlashCardModel.fromMap(e))
//         .toList();

//     // فاصله زمانی باکس‌ها برحسب روز
//     List<int> intervals = [1, 2, 4, 8, 16];

//     int now = DateTime.now().millisecondsSinceEpoch;

//     return allCards.where((card) {
//       // کارت تازه همیشه برای مرور آماده است
//       if (card.lastReviewed == 0) return true;

//       int intervalDays = intervals[(card.box - 1).clamp(0, 4)];
//       int nextReview = card.lastReviewed + intervalDays * 24 * 60 * 60 * 1000;

//       return now >= nextReview;
//     }).toList();
//   }
// }

// import 'package:leitner_flutter_app/data/models/flashcard_model.dart';
import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/flashcard_model.dart';
import '../data/models/deck_model.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // ------------------------------------------------------------
  // 🔥 ایجاد دیتابیس
  // ------------------------------------------------------------

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'leitner.db');

    return await openDatabase(path, version: 1, onCreate: _createDB, onUpgrade: _upgradeDB);
  }
  // ------------------------------------------------------------
  // 🔥 ساخت جداول
  // ------------------------------------------------------------

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english TEXT NOT NULL,
        persian TEXT NOT NULL,
        phonetic TEXT,
        box INTEGER NOT NULL,
        lastReviewed INTEGER NOT NULL,
        deckId INTEGER NOT NULL,
        FOREIGN KEY(deckId) REFERENCES decks(id)
      );
    ''');
    // ⭐ جدول XP — همیشه یک ردیف دارد
    await db.execute('''
      CREATE TABLE xp_data (
        id INTEGER PRIMARY KEY,
        xp INTEGER DEFAULT 0,
        level INTEGER NOT NULL,
        lastDailyReward INTEGER DEFAULT 0
      )
    ''');

    // مقدار اولیه
    await db.insert("xp_data", {"id": 1, "xp": 0, "level": 1, "lastDailyReward": 0});
  }
  // ------------------------------------------------------------
  // 🔥 آپگرید دیتابیس (اگر نسخه قبلی دارید)
  // ------------------------------------------------------------

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {}
  }

  Future<List<FlashCardModel>> cardsByBox(int box) async {
    final rows = await _db!.query('cards', where: 'box = ?', whereArgs: [box]);
    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }
  // ---------------------------
  //  DECK FUNCTIONS
  // ---------------------------

  Future<int> insertDeck(DeckModel deck) async {
    final db = await database;
    return await db.insert('decks', deck.toMap());
  }

  Future<List<DeckModel>> allDecks() async {
    final db = await database;
    final rows = await db.query('decks');
    return rows.map((e) => DeckModel.fromMap(e)).toList();
  }

  // ---------------------------
  //  CARD FUNCTIONS
  // ---------------------------

  Future<int> insertCard(FlashCardModel card) async {
    final db = await database;
    return await db.insert('cards', card.toMap());
  }

  Future<List<FlashCardModel>> allCards() async {
    final rows = await _db!.query('cards');
    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }

  Future<List<FlashCardModel>> pagedCards({
    int limit = 50,
    int offset = 0,
    String? search,
    int box = 0, // ← فیلتر جدید
  }) async {
    // شرایط WHERE را یکجا جمع می‌کنیم
    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    // String whereClause = '';
    // List<dynamic> whereArgs = [];
    if (search != null && search.isNotEmpty) {
      conditions.add('(english LIKE ? OR persian LIKE ?)');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }
    // فیلتر بر اساس BOX
    if (box != 0) {
      conditions.add('box = ?');
      whereArgs.add(box);
    }

    // ساخت WHERE نهایی
    String? whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final rows = await _db!.query(
      'cards',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }

  Future<List<FlashCardModel>> cardsByDeck(int deckId) async {
    final db = await database;
    final rows = await db.query('cards', where: 'deckId = ?', whereArgs: [deckId]);
    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }

  Future<int> updateCard(FlashCardModel card) async {
    final db = await database;
    return await db.update('cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  /// days: تعداد روزهایی که باید از تاریخ آخرین مرور کم شود
  Future<void> shiftReviewDates(int days) async {
    final db = await database;

    // تبدیل روز به میلی‌ثانیه
    int diff = days * 24 * 60 * 60 * 1000;

    // تمام کارت‌ها را بگیر
    final rows = await db.query('cards');

    for (var row in rows) {
      int id = row['id'] as int;
      int last = row['lastReviewed'] as int;

      // اگر کارت هرگز مرور نشده باشد، دست نزنید
      if (last == 0) continue;

      int newTime = last - diff;

      // اجازه نده زمان منفی شود
      if (newTime < 0) newTime = 0;

      await db.update('cards', {'lastReviewed': newTime}, where: 'id = ?', whereArgs: [id]);
    }
  }

  // -------------------------------------------------
  //  LEITNER — GET DUE CARDS FOR A SPECIFIC DECK
  // -------------------------------------------------

  Future<List<FlashCardModel>> dueCards(int deckId) async {
    final db = await database;
    final rows = await db.query('cards', where: 'deckId = ?', whereArgs: [deckId]);

    final cards = rows.map((e) => FlashCardModel.fromMap(e)).toList();

    final intervals = [1, 2, 4, 8, 16];
    final now = DateTime.now().millisecondsSinceEpoch;

    return cards.where((card) {
      if (card.lastReviewed == 0) return true;

      int interval = intervals[(card.box - 1).clamp(0, 4)];
      int next = card.lastReviewed + interval * 86400000;

      return now >= next;
    }).toList();
  }
  // ------------------------------------------------------------
  // ⭐ سیستم XP و Level
  // ------------------------------------------------------------

  // خواندن XP
  Future<int> getXP() async {
    final db = await database;
    final data = await db.query("xp_data", where: "id = 1");
    return data.first["xp"] as int;
  }

  // ذخیره XP
  Future<void> setXP(int xp) async {
    final db = await database;
    await db.update("xp_data", {"xp": xp}, where: "id = 1");
  }

  // افزودن XP
  Future<void> addXP(int amount) async {
    final db = await database;

    final data = await getXPData();
    int xp = data["xp"]!;
    int level = data["level"]!;

    xp += amount;

    // فرمول XP مورد نیاز برای لول‌آپ
    int need = 50 + (level - 1) * 20;

    // لول‌آپ اتوماتیک
    while (xp >= need) {
      xp -= need;
      level++;
      need = 50 + (level - 1) * 20;
    }

    await db.update("xp_data", {"xp": xp, "level": level}, where: "id = 1");
  }

  // Level = ریشه دوم XP
  int calculateLevel(int xp) {
    return sqrt(xp / 100).toInt();
  }

  // 🔥 ذخیره زمان آخرین پاداش روزانه
  Future<int> getLastDailyReward() async {
    final db = await database;
    final data = await db.query("xp_data", where: "id = 1");
    return data.first["lastDailyReward"] as int;
  }

  Future<void> setLastDailyReward(int timestamp) async {
    final db = await database;
    await db.update("xp_data", {"lastDailyReward": timestamp}, where: "id = 1");
  }

  Future<Map<String, int>> getXPData() async {
    final db = await database;

    final res = await db.query("xp_data");

    if (res.isEmpty) {
      // اگر هیچ رکوردی نبود، بسازیم
      await db.insert("xp_data", {"xp": 0, "level": 1});
      return {"xp": 0, "level": 1};
    }

    final row = res.first;

    int xp = row["xp"] is int ? row["xp"] as int : 0;
    int level = row["level"] is int ? row["level"] as int : 1;

    return {"xp": xp, "level": level};
  }

  Future<void> addXPData(int amount) async {
    final db = _db!;
    final data = await getXPData();

    int xp = data["xp"]!;
    int level = data["level"]!;

    xp += amount;

    int xpNeeded = 50 + (level - 1) * 20;

    // LEVEL UP
    while (xp >= xpNeeded) {
      xp -= xpNeeded;
      level++;
      xpNeeded = 50 + (level - 1) * 20;
    }

    await db.update("xp_data", {"xp": xp, "level": level}, where: "id = 1");
  }

  // -------------------------------------------------
  //  LEITNER — COUNT OF DUE CARDS (TODAY)
  // -------------------------------------------------

  Future<int> dueCount(int deckId) async {
    List<FlashCardModel> list = await dueCards(deckId);
    return list.length;
  }
}
