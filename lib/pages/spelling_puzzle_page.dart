import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';

class SpellingPuzzlePage extends StatefulWidget {
  const SpellingPuzzlePage({super.key});

  @override
  State<SpellingPuzzlePage> createState() => _SpellingPuzzlePageState();
}

class _SpellingPuzzlePageState extends State<SpellingPuzzlePage> with SingleTickerProviderStateMixin {
  List<FlashCardModel> _cards = [];
  int _index = 0;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final TextEditingController _answerController = TextEditingController();
  final FlutterTts _tts = FlutterTts();

  String _puzzleWord = "";
  String _originalWord = "";

  bool _isLoading = true;
  bool? _correctResult; // null=بدون نتیجه / true=درست / false=غلط

  @override
  void initState() {
    super.initState();
    _loadCards();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _answerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // 1) بارگیری کارت‌ها مرحله‌ای بر اساس box
  // --------------------------------------------------------
  Future<void> _loadCards() async {
    final db = DBHelper.instance;

    List<FlashCardModel> all = [];

    // box=1 → box=2 → ...
    for (int b = 1; b <= 5; b++) {
      final batch = await db.pagedCards(limit: 200, offset: 0, search: null);

      final filtered = batch.where((c) => c.box == b).toList();
      all.addAll(filtered);
      if (all.length >= 200) break;
    }

    all.shuffle();

    if (mounted) {
      setState(() {
        _cards = all;
        _isLoading = false;
        _index = 0;
      });

      if (_cards.isNotEmpty) _preparePuzzle();
    }
  }

  // --------------------------------------------------------
  // 2) ساخت پازل: حذف تصادفی ۳۰٪ حروف — هر بار جدید
  // --------------------------------------------------------
  void _preparePuzzle() {
    final word = _cards[_index].english.trim();
    _originalWord = word;

    _puzzleWord = _hideRandomLetters(word, percent: 0.30);
    _answerController.clear();
    _correctResult = null;

    setState(() {});
  }

  String _hideRandomLetters(String word, {double percent = 0.30}) {
    final chars = word.split("");
    final rnd = Random();

    int removeCount = max(1, (chars.length * percent).round());
    final indexes = <int>{};

    while (indexes.length < removeCount) {
      int i = rnd.nextInt(chars.length);
      if (RegExp(r'[A-Za-z]').hasMatch(chars[i])) {
        indexes.add(i);
      }
    }

    for (int i in indexes) {
      chars[i] = "_";
    }

    return chars.join();
  }

  // --------------------------------------------------------
  // 3) بررسی پاسخ
  // --------------------------------------------------------
  void _checkAnswer() {
    final user = _answerController.text.trim().toLowerCase();
    final correct = _originalWord.toLowerCase();

    if (user == correct) {
      _correctResult = true;
      _playSuccessAnim();
      _nextWord();
    } else {
      _correctResult = false;
      _playErrorAnim();
      setState(() {});
    }
  }

  Future<void> _nextWord() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_index + 1 < _cards.length) {
      setState(() => _index++);
      _preparePuzzle();
    } else {
      setState(() {});
    }
  }

  // --------------------------------------------------------
  // 4) "بلدم" — رد سریع
  // --------------------------------------------------------
  void _skip() => _nextWord();

  // --------------------------------------------------------
  // 5) پخش صدا
  // --------------------------------------------------------
  Future<void> _speak() async {
    await _tts.setLanguage("en-US");
    await _tts.speak(_originalWord);
  }

  // --------------------------------------------------------
  // 6) انیمیشن موفق / خطا
  // --------------------------------------------------------
  void _playSuccessAnim() {
    _animController.forward().then((_) => _animController.reverse());
  }

  void _playErrorAnim() {
    _animController.forward().then((_) => _animController.reverse());
  }

  // --------------------------------------------------------
  // 7) UI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return const Scaffold(body: Center(child: Text("هیچ لغتی برای تمرین موجود نیست")));
    }

    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text("تمرین املا"),
        actions: [
          Center(child: Text("${_index + 1} / ${_cards.length}", style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.volume_up), onPressed: _speak),
          IconButton(icon: const Icon(Icons.skip_next), tooltip: "بلدم", onPressed: _skip),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ⭐ پازل با انیمیشن و تغییر رنگ (درست/غلط)
            ScaleTransition(
              scale: _scaleAnim,
              child: Text(
                _puzzleWord,
                style: TextStyle(
                  fontSize: 40,
                  letterSpacing: 2,
                  color: _correctResult == null
                      ? Colors.black
                      : _correctResult == true
                      ? Colors.green
                      : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),

            // ⭐ پیام درست / غلط
            if (_correctResult != null)
              Text(
                _correctResult == true ? "Correct!" : "Wrong!",
                style: TextStyle(
                  fontSize: 24,
                  color: _correctResult == true ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 30),

            TextField(
              controller: _answerController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26),
              decoration: InputDecoration(labelText: "املای کامل را وارد کن", border: OutlineInputBorder()),
              onSubmitted: (_) => _checkAnswer(),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: _checkAnswer, child: const Text("بررسی")),

            const SizedBox(height: 20),

            Text(card.persian, style: const TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
