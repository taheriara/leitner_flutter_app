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

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'leitner.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

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
        box INTEGER NOT NULL,
        lastReviewed INTEGER NOT NULL,
        deckId INTEGER NOT NULL,
        FOREIGN KEY(deckId) REFERENCES decks(id)
      );
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE decks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        );
      ''');

      await db.execute('ALTER TABLE cards ADD COLUMN deckId INTEGER DEFAULT 1');
    }
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
    int limit = 5,
    int offset = 0,
    String? search,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (search != null && search.isNotEmpty) {
      whereClause = 'english LIKE ? OR persian LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }

    final rows = await _db!.query(
      'cards',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }

  Future<List<FlashCardModel>> cardsByDeck(int deckId) async {
    final db = await database;
    final rows = await db.query(
      'cards',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );
    return rows.map((e) => FlashCardModel.fromMap(e)).toList();
  }

  Future<int> updateCard(FlashCardModel card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
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

      await db.update(
        'cards',
        {'lastReviewed': newTime},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // -------------------------------------------------
  //  LEITNER — GET DUE CARDS FOR A SPECIFIC DECK
  // -------------------------------------------------

  Future<List<FlashCardModel>> dueCards(int deckId) async {
    final db = await database;
    final rows = await db.query(
      'cards',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );

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

  // -------------------------------------------------
  //  LEITNER — COUNT OF DUE CARDS (TODAY)
  // -------------------------------------------------

  Future<int> dueCount(int deckId) async {
    List<FlashCardModel> list = await dueCards(deckId);
    return list.length;
  }
}
