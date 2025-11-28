import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';

class SpellingPracticePage extends StatefulWidget {
  @override
  _SpellingPracticePageState createState() => _SpellingPracticePageState();
}

class _SpellingPracticePageState extends State<SpellingPracticePage> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _answerController = TextEditingController();

  List<FlashCardModel> _queue = [];
  int _index = 0;
  int _correct = 0;
  bool _loading = true;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  /// مرحله ۱: لود کارت‌ها به ترتیب box1 → box2 → box3 ...
  Future<void> _loadQueue() async {
    List<FlashCardModel> result = [];

    for (int box = 1; box <= 5; box++) {
      if (result.length > 200) break; // جلوگیری از فشار زیاد
      final page = await DBHelper.instance.pagedCards(
        limit: 100, // فقط 100 تا از هر box
        offset: 0,
        search: null,
        box: box,
      );
      result.addAll(page);
      if (result.length >= 200) break;
    }

    result.shuffle();

    setState(() {
      _queue = result;
      _loading = false;
    });
  }

  /// پخش صوت
  Future<void> _speak(String word) async {
    await _tts.setLanguage("en-US");
    await _tts.speak(word);
  }

  /// ساخت الگوی fill-in-the-blank
  String _makePuzzle(String word) {
    if (word.length <= 3) return word;

    final chars = word.split('');
    final removeCount = (word.length / 3).round();

    final rnd = Random();
    final removedIndexes = <int>{};

    while (removedIndexes.length < removeCount) {
      int i = rnd.nextInt(word.length - 1);
      if (i == 0 || i == word.length - 1) continue; // اول و آخر حذف نشود
      removedIndexes.add(i);
    }

    for (var i in removedIndexes) {
      chars[i] = "_";
    }

    return chars.join('');
  }

  void _checkAnswer() {
    final user = _answerController.text.trim().toLowerCase();
    final correct = _queue[_index].english.trim().toLowerCase();

    if (user == correct) {
      setState(() {
        _correct++;
        _showAnswer = false;
        _answerController.clear();
        _index++;
      });
    } else {
      setState(() {
        _showAnswer = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text("Spelling Practice")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_index >= _queue.length) {
      return Scaffold(
        appBar: AppBar(title: Text("Spelling Practice")),
        body: Center(
          child: Text(
            "پایان تمرین!\n$_correct از ${_queue.length} درست",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    final card = _queue[_index];
    final puzzle = _makePuzzle(card.english);

    return Scaffold(
      appBar: AppBar(
        title: Text("تمرین املا"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text("${_index + 1} / ${_queue.length}"),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Text(puzzle, style: TextStyle(fontSize: 32, letterSpacing: 3), textAlign: TextAlign.center),
            SizedBox(height: 20),

            // دکمه پخش صوت
            IconButton(icon: Icon(Icons.volume_up, size: 36), onPressed: () => _speak(card.english)),

            SizedBox(height: 20),

            TextField(
              controller: _answerController,
              decoration: InputDecoration(labelText: "اینجا املا را وارد کن", border: OutlineInputBorder()),
              onSubmitted: (_) => _checkAnswer(),
            ),

            SizedBox(height: 20),

            ElevatedButton(onPressed: _checkAnswer, child: Text("بررسی")),

            if (_showAnswer)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("جواب صحیح: ${card.english}", style: TextStyle(fontSize: 20, color: Colors.red)),
              ),

            Spacer(),

            Text("درست‌ها: $_correct", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
