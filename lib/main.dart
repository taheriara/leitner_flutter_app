// Leitner Flashcard App (English -> Persian)
// Single-file Flutter app (main.dart)
// Dependencies (add to pubspec.yaml):
//   sdk: ">=2.18.0 <3.0.0"
//   flutter:
//     sdk: flutter
//
// dependencies:
//   flutter:
//     sdk: flutter
//   sqflite: ^2.2.8+4
//   path_provider: ^2.0.15
//   path: ^1.8.3
//   translator: ^0.1.7
//   intl: ^0.18.1
//
// Notes:
// - translator package uses Google Translate unofficially and requires internet.
// - If you prefer a different translation API (LibreTranslate, Google Cloud Translate), replace the translate() call in _translateToPersian.
// - This is a compact, single-file example for clarity. For production, split into multiple files and add error handling.

import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/pages/slide.dart';
import 'data/db_helper.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await DBHelper.instance.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leitner Flashcards',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

//---------------------------------------------

// class FlashCardModel {
//   int? id;
//   String english;
//   String persian;
//   int box; // 1..5
//   int lastReviewed; // epoch millis

//   FlashCardModel({
//     this.id,
//     required this.english,
//     required this.persian,
//     this.box = 1,
//     int? lastReviewed,
//   }) : this.lastReviewed = lastReviewed ?? 0;

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'english': english,
//       'persian': persian,
//       'box': box,
//       'lastReviewed': lastReviewed,
//     };
//   }

//   static FlashCardModel fromMap(Map<String, dynamic> m) {
//     return FlashCardModel(
//       id: m['id'] as int?,
//       english: m['english'] as String,
//       persian: m['persian'] as String,
//       box: m['box'] as int,
//       lastReviewed: m['lastReviewed'] as int,
//     );
//   }
// }

// class DBHelper {
//   DBHelper._privateConstructor();
//   static final DBHelper instance = DBHelper._privateConstructor();

//   Database? _db;

//   Future<void> init() async {
//     if (_db != null) return;
//     Directory documentsDirectory = await getApplicationDocumentsDirectory();
//     String path = p.join(documentsDirectory.path, 'leitner.db');
//     _db = await openDatabase(path, version: 1, onCreate: _onCreate);
//   }

//   Future _onCreate(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE cards(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         english TEXT NOT NULL,
//         persian TEXT NOT NULL,
//         box INTEGER NOT NULL,
//         lastReviewed INTEGER NOT NULL
//       )
//     ''');
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
//     return rows.map((r) => FlashCardModel.fromMap(r)).toList();
//   }

//   Future<List<FlashCardModel>> dueCards() async {
//     final now = DateTime.now().millisecondsSinceEpoch;
//     // Simple strategy: return all cards (you can implement spaced intervals per box)
//     final rows = await _db!.query('cards');
//     return rows.map((r) => FlashCardModel.fromMap(r)).toList();
//   }

//   Future<List<FlashCardModel>> cardsByBox(int box) async {
//     final rows = await _db!.query('cards', where: 'box = ?', whereArgs: [box]);
//     return rows.map((r) => FlashCardModel.fromMap(r)).toList();
//   }
// }

// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<int> counts = [0, 0, 0, 0, 0];

//   @override
//   void initState() {
//     super.initState();
//     _loadCounts();
//   }

//   Future<void> _loadCounts() async {
//     final all = await DBHelper.instance.allCards();
//     final newCounts = [0, 0, 0, 0, 0];
//     for (var c in all) {
//       final idx = (c.box - 1).clamp(0, 4);
//       newCounts[idx]++;
//     }
//     setState(() => counts = newCounts);
//   }

//   Widget _boxCard(int boxNumber) {
//     return Card(
//       child: ListTile(
//         title: Text('Box $boxNumber'),
//         subtitle: Text('${counts[boxNumber - 1]} کارت'),
//         trailing: Icon(Icons.chevron_right),
//         onTap: () async {
//           await Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => BoxDetailPage(box: boxNumber)),
//           );
//           await _loadCounts();
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Leitner Box (EN → FA)'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.play_arrow),
//             tooltip: 'Study',
//             onPressed: () async {
//               await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => StudyPage()),
//               );
//               await _loadCounts();
//             },
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadCounts,
//         child: ListView(
//           padding: EdgeInsets.all(12),
//           children: [
//             _boxCard(1),
//             _boxCard(2),
//             _boxCard(3),
//             _boxCard(4),
//             _boxCard(5),
//             SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () async {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => AddCardPage()),
//                 );
//                 await _loadCounts();
//               },
//               icon: Icon(Icons.add),
//               label: Text('اضافه کردن کارت'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class AddCardPage extends StatefulWidget {
//   @override
//   _AddCardPageState createState() => _AddCardPageState();
// }

// class _AddCardPageState extends State<AddCardPage> {
//   final _englishController = TextEditingController();
//   final _persianController = TextEditingController();
//   bool _autoTranslate = true;
//   Timer? _debounce;
//   bool _isTranslating = false;
//   final GoogleTranslator _translator = GoogleTranslator();

//   @override
//   void initState() {
//     super.initState();
//     _englishController.addListener(_onEnglishChanged);
//   }

//   void _onEnglishChanged() {
//     if (!_autoTranslate) return;
//     _debounce?.cancel();
//     _debounce = Timer(Duration(milliseconds: 800), () async {
//       final text = _englishController.text.trim();
//       if (text.isEmpty) return;
//       // Only auto-fill if user hasn't typed a Persian answer manually
//       if (_persianController.text.trim().isNotEmpty) return;
//       setState(() => _isTranslating = true);
//       try {
//         String tr = await _translateToPersian(text);
//         // only set if english hasn't changed since starting
//         if (_englishController.text.trim() == text) {
//           _persianController.text = tr;
//         }
//       } catch (e) {
//         // ignore translation errors
//       }
//       if (mounted) setState(() => _isTranslating = false);
//     });
//   }

//   Future<String> _translateToPersian(String text) async {
//     // translator package uses Google Translate behind the scenes.
//     final res = await _translator.translate(text, to: 'fa');
//     return res.text;
//   }

//   @override
//   void dispose() {
//     _englishController.dispose();
//     _persianController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _saveCard() async {
//     final eng = _englishController.text.trim();
//     final fa = _persianController.text.trim();
//     if (eng.isEmpty || fa.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('لطفاً هر دو قسمت را پر کنید')));
//       return;
//     }
//     final card = FlashCardModel(
//       english: eng,
//       persian: fa,
//       box: 1,
//       lastReviewed: 0,
//     );
//     await DBHelper.instance.insertCard(card);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('اضافه کردن کارت')),
//       body: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           children: [
//             TextField(
//               controller: _englishController,
//               decoration: InputDecoration(
//                 labelText: 'English (front)',
//                 hintText: 'enter English word or phrase',
//               ),
//             ),
//             SizedBox(height: 12),
//             Stack(
//               alignment: Alignment.centerRight,
//               children: [
//                 TextField(
//                   controller: _persianController,
//                   decoration: InputDecoration(
//                     labelText: 'Persian (back)',
//                     hintText: 'translation will appear here',
//                   ),
//                 ),
//                 if (_isTranslating)
//                   Padding(
//                     padding: EdgeInsets.only(right: 8),
//                     child: SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                   ),
//               ],
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 Checkbox(
//                   value: _autoTranslate,
//                   onChanged: (v) => setState(() => _autoTranslate = v ?? true),
//                 ),
//                 Expanded(
//                   child: Text(
//                     'پر کردن خودکار ترجمه با استفاده از Google Translate (اینترنت لازم است)',
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.refresh),
//                   tooltip: 'ترجمه دستی',
//                   onPressed: () async {
//                     final text = _englishController.text.trim();
//                     if (text.isEmpty) return;
//                     setState(() => _isTranslating = true);
//                     try {
//                       final tr = await _translateToPersian(text);
//                       _persianController.text = tr;
//                     } catch (e) {
//                       ScaffoldMessenger.of(
//                         context,
//                       ).showSnackBar(SnackBar(content: Text('خطا در ترجمه')));
//                     }
//                     if (mounted) setState(() => _isTranslating = false);
//                   },
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _saveCard,
//               icon: Icon(Icons.save),
//               label: Text('ذخیره'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BoxDetailPage extends StatefulWidget {
//   final int box;
//   BoxDetailPage({required this.box});

//   @override
//   _BoxDetailPageState createState() => _BoxDetailPageState();
// }

// class _BoxDetailPageState extends State<BoxDetailPage> {
//   List<FlashCardModel> cards = [];

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     final c = await DBHelper.instance.cardsByBox(widget.box);
//     setState(() => cards = c);
//   }

//   Future<void> _delete(int id) async {
//     await DBHelper.instance.deleteCard(id);
//     await _load();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Box ${widget.box}')),
//       body: ListView.builder(
//         itemCount: cards.length,
//         itemBuilder: (context, i) {
//           final c = cards[i];
//           return Card(
//             child: ListTile(
//               title: Text(c.english),
//               subtitle: Text(c.persian),
//               trailing: IconButton(
//                 icon: Icon(Icons.delete),
//                 onPressed: () => _delete(c.id!),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class StudyPage extends StatefulWidget {
//   @override
//   _StudyPageState createState() => _StudyPageState();
// }

// class _StudyPageState extends State<StudyPage> {
//   List<FlashCardModel> _queue = [];
//   int _index = 0;
//   bool _showBack = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadQueue();
//   }

//   Future<void> _loadQueue() async {
//     final all = await DBHelper.instance.allCards();
//     // Simple ordering: shuffle and show. You can implement due-based scheduling.
//     all.shuffle();
//     setState(() {
//       _queue = all;
//       _index = 0;
//       _showBack = false;
//     });
//   }

//   void _markCorrect() async {
//     if (_index >= _queue.length) return;
//     final card = _queue[_index];
//     card.box = (card.box + 1).clamp(1, 5);
//     card.lastReviewed = DateTime.now().millisecondsSinceEpoch;
//     await DBHelper.instance.updateCard(card);
//     _next();
//   }

//   void _markIncorrect() async {
//     if (_index >= _queue.length) return;
//     final card = _queue[_index];
//     card.box = 1;
//     card.lastReviewed = DateTime.now().millisecondsSinceEpoch;
//     await DBHelper.instance.updateCard(card);
//     _next();
//   }

//   void _next() {
//     setState(() {
//       _index++;
//       _showBack = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final done = _index >= _queue.length;
//     return Scaffold(
//       appBar: AppBar(title: Text('Study')),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: done
//             ? Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('آزمون تمام شد', style: TextStyle(fontSize: 20)),
//                     SizedBox(height: 12),
//                     ElevatedButton(
//                       onPressed: _loadQueue,
//                       child: Text('شروع دوباره'),
//                     ),
//                   ],
//                 ),
//               )
//             : Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Text(
//                     'Card ${_index + 1} / ${_queue.length}',
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 20),
//                   Expanded(
//                     child: Card(
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showBack = !_showBack),
//                         onHorizontalDragEnd: (details) {
//                           if (details.primaryVelocity == null) return;
//                           if (details.primaryVelocity! > 0) {
//                             _markCorrect();
//                           } else if (details.primaryVelocity! < 0) {
//                             _markIncorrect();
//                           }
//                         },
//                         child: Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   _showBack
//                                       ? _queue[_index].persian
//                                       : _queue[_index].english,
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(fontSize: 28),
//                                 ),
//                                 SizedBox(height: 12),
//                                 if (!_showBack)
//                                   Text(
//                                     '(لمس کنید تا ترجمه را ببینید)',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   '↔ برای درست/نادرست بکشید',
//                                   style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                           ),
//                           onPressed: _markIncorrect,
//                           icon: Icon(Icons.close),
//                           label: Text('نادرست'),
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                           ),
//                           onPressed: _markCorrect,
//                           icon: Icon(Icons.check),
//                           label: Text('درست'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }
