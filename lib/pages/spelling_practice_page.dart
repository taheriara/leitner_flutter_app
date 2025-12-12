// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import '../data/db_helper.dart';
// import '../data/models/flashcard_model.dart';

// class SpellingPracticePage extends StatefulWidget {
//   @override
//   _SpellingPracticePageState createState() => _SpellingPracticePageState();
// }

// class _SpellingPracticePageState extends State<SpellingPracticePage> {
//   final FlutterTts _tts = FlutterTts();
//   final TextEditingController _answerController = TextEditingController();

//   List<FlashCardModel> _queue = [];
//   int _index = 0;
//   int _correct = 0;
//   bool _loading = true;
//   bool _showAnswer = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadQueue();
//   }

//   /// مرحله ۱: لود کارت‌ها به ترتیب box1 → box2 → box3 ...
//   Future<void> _loadQueue() async {
//     List<FlashCardModel> result = [];

//     for (int box = 1; box <= 5; box++) {
//       if (result.length > 200) break; // جلوگیری از فشار زیاد
//       final page = await DBHelper.instance.pagedCards(
//         limit: 100, // فقط 100 تا از هر box
//         offset: 0,
//         search: null,
//         box: box,
//       );
//       result.addAll(page);
//       if (result.length >= 200) break;
//     }

//     result.shuffle();

//     setState(() {
//       _queue = result;
//       _loading = false;
//     });
//   }

//   /// پخش صوت
//   Future<void> _speak(String word) async {
//     await _tts.setLanguage("en-US");
//     await _tts.speak(word);
//   }

//   /// ساخت الگوی fill-in-the-blank
//   String _makePuzzle(String word) {
//     if (word.length <= 3) return word;

//     final chars = word.split('');
//     final removeCount = (word.length / 3).round();

//     final rnd = Random();
//     final removedIndexes = <int>{};

//     while (removedIndexes.length < removeCount) {
//       int i = rnd.nextInt(word.length - 1);
//       if (i == 0 || i == word.length - 1) continue; // اول و آخر حذف نشود
//       removedIndexes.add(i);
//     }

//     for (var i in removedIndexes) {
//       chars[i] = "_";
//     }

//     return chars.join('');
//   }

//   void _checkAnswer() {
//     final user = _answerController.text.trim().toLowerCase();
//     final correct = _queue[_index].english.trim().toLowerCase();

//     if (user == correct) {
//       setState(() {
//         _correct++;
//         _showAnswer = false;
//         _answerController.clear();
//         _index++;
//       });
//     } else {
//       setState(() {
//         _showAnswer = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Spelling Practice")),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_index >= _queue.length) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Spelling Practice")),
//         body: Center(
//           child: Text(
//             "پایان تمرین!\n$_correct از ${_queue.length} درست",
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 22),
//           ),
//         ),
//       );
//     }

//     final card = _queue[_index];
//     final puzzle = _makePuzzle(card.english);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("تمرین املا"),
//         actions: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Text("${_index + 1} / ${_queue.length}"),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(18),
//         child: Column(
//           children: [
//             Text(
//               puzzle,
//               style: TextStyle(fontSize: 32, letterSpacing: 3),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),

//             // دکمه پخش صوت
//             IconButton(
//               icon: Icon(Icons.volume_up, size: 36),
//               onPressed: () => _speak(card.english),
//             ),

//             SizedBox(height: 20),

//             TextField(
//               controller: _answerController,
//               decoration: InputDecoration(
//                 labelText: "اینجا املا را وارد کن",
//                 border: OutlineInputBorder(),
//               ),
//               onSubmitted: (_) => _checkAnswer(),
//             ),

//             SizedBox(height: 20),

//             ElevatedButton(onPressed: _checkAnswer, child: Text("بررسی")),

//             if (_showAnswer)
//               Padding(
//                 padding: EdgeInsets.only(top: 20),
//                 child: Text(
//                   "جواب صحیح: ${card.english}",
//                   style: TextStyle(fontSize: 20, color: Colors.red),
//                 ),
//               ),

//             Spacer(),

//             Text("درست‌ها: $_correct", style: TextStyle(fontSize: 16)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// spelling_puzzle_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';

class SpellingPuzzlePage2 extends StatefulWidget {
  const SpellingPuzzlePage2({super.key});

  @override
  State<SpellingPuzzlePage2> createState() => _SpellingPuzzlePage2State();
}

class _SpellingPuzzlePage2State extends State<SpellingPuzzlePage2> with SingleTickerProviderStateMixin {
  List<FlashCardModel> _cards = [];
  int _index = 0;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  final FlutterTts _tts = FlutterTts();

  // حالت پازل
  String _originalWord = "";
  List<String> _puzzleChars = []; // حروف و '_' های پازل
  List<String> _userChars = []; // حالت فعلی کاربر (برای نمایش)
  List<String> _optionLetters = []; // گزینه‌ها برای انتخاب
  List<bool> _optionUsed = []; // استفاده شده / نشده
  Map<int, int> _posToOptionIndex = {}; // position -> optionIndex (برای undo)

  bool _isLoading = true;
  bool? _correctResult; // null = no result, true/false
  int _correctCount = 0;
  int _wrongCount = 0;

  final Random _rnd = Random();

  bool Spelling_finish = false;

  @override
  void initState() {
    super.initState();
    _loadCards();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // -------------------------
  // بارگذاری کارت‌ها (مرحله‌ای: box=1 سپس box=2 ...)
  // -------------------------
  Future<void> _loadCards() async {
    final db = DBHelper.instance;

    List<FlashCardModel> all = [];

    // خواندن دسته‌ای (نه همه یکجا). اینجا برای هر باکس یک batch می‌گیریم.
    for (int b = 1; b <= 5; b++) {
      final batch = await db.pagedCards(limit: 200, offset: 0, search: null);
      final filtered = batch.where((c) => c.box == b).toList();
      all.addAll(filtered);
      if (all.length >= 500) break; // حداکثر جمع‌آوری اولیه
    }

    all.shuffle();

    setState(() {
      _cards = all;
      _index = 0;
      _isLoading = false;
      _correctCount = 0;
      _wrongCount = 0;
    });

    if (_cards.isNotEmpty) _preparePuzzle();
  }

  // -------------------------
  // آماده‌سازی پازل: حذف تصادفی 30% حروف، ساخت گزینه‌ها (حروف حذف شده + حروف اضافی)
  // -------------------------
  void _preparePuzzle() {
    if (_cards.isEmpty || _index >= _cards.length) return;
    _correctResult = null;
    _posToOptionIndex.clear();

    _originalWord = _cards[_index].english.trim();
    // قطعات کلمه به حروف جدا (نگهداری کاراکترها همانطور که هستند)
    final chars = _originalWord.split('');

    // تعیین ایندکس‌های حذف شونده (فقط حروف لاتین)
    final letterIndexes = <int>[];
    for (int i = 0; i < chars.length; i++) {
      if (RegExp(r'[A-Za-z]').hasMatch(chars[i])) letterIndexes.add(i);
    }

    int removeCount = max(1, (letterIndexes.length * 0.30).round());
    final indexesToRemove = <int>{};
    while (indexesToRemove.length < removeCount && indexesToRemove.length < letterIndexes.length) {
      indexesToRemove.add(letterIndexes[_rnd.nextInt(letterIndexes.length)]);
    }

    // _puzzleChars: حروف یا '_' به عنوان جای خالی
    _puzzleChars = List<String>.from(chars);
    for (final i in indexesToRemove) {
      _puzzleChars[i] = '_';
    }

    // userChars با همان طول، مقادیر غیر-خالی همان حرف، برای خالی '_' میگذاریم '_'
    _userChars = List<String>.from(_puzzleChars);

    // ساخت مجموعه گزینه ها: شامل همه حروفی که حذف شده + چند حرف تصادفی اضافی
    final removedLetters = <String>[];
    for (final i in indexesToRemove) {
      removedLetters.add(chars[i]);
    }

    // تعداد هدف برای گزینه‌ها
    int targetOptions = max(removedLetters.length * 2, 6); // حداقل 6 گزینه
    final options = <String>[];
    options.addAll(removedLetters);

    // اضافه کردن حروف اضافی تصادفی (از الفبای انگلیسی)
    const alphabet = 'abcdefghijklmnopqrstuvwxyz';
    while (options.length < targetOptions) {
      final c = alphabet[_rnd.nextInt(alphabet.length)];
      // اجازه تکرار حروف در گزینه‌ها ولی اگر خیلی تکراری شد می‌توان محدود کرد
      options.add(c);
    }

    options.shuffle();

    _optionLetters = options;
    _optionUsed = List<bool>.filled(_optionLetters.length, false);

    // reset state
    _correctResult = null;
    setState(() {});
  }

  // -------------------------
  // انتخاب یک گزینه
  // -------------------------
  void _selectOption(int optionIndex) {
    if (_optionUsed[optionIndex]) return;
    // پیدا کردن اولین جای خالی (چپ به راست)
    final pos = _userChars.indexWhere((c) => c == '_');
    if (pos == -1) return; // پر است

    final letter = _optionLetters[optionIndex];
    _userChars[pos] = letter;
    _optionUsed[optionIndex] = true;
    _posToOptionIndex[pos] = optionIndex;

    setState(() {});

    // اگر همه جای خالی پر شد، بررسی خودکار
    if (!_userChars.contains('_')) {
      _checkAnswer();
    }
  }

  // -------------------------
  // پاک کردن یک حرف (آخرین حرفی که کاربر وارد کرده)
  // -------------------------
  void _deleteOne() {
    // پیدا کردن آخرین position که کاربر در آن حرف وارد کرده (یعنی جای اصلی '_' بود ولی userChars != '_')
    int lastFilledPos = -1;
    for (int i = _userChars.length - 1; i >= 0; i--) {
      if (_puzzleChars[i] == '_' && _userChars[i] != '_') {
        lastFilledPos = i;
        break;
      }
    }
    if (lastFilledPos == -1) return;

    // re-enable مربوط به optionIndex
    final optionIndex = _posToOptionIndex[lastFilledPos];
    if (optionIndex != null) {
      _optionUsed[optionIndex] = false;
      _posToOptionIndex.remove(lastFilledPos);
    }
    // خالی کردن آن موقعیت
    _userChars[lastFilledPos] = '_';
    _correctResult = null;
    setState(() {});
  }

  // -------------------------
  // بررسی پاسخ کاربر (مقایسه کامل رشته)
  // -------------------------
  void _checkAnswer() {
    final userWord = _userChars.join();
    final correct = _originalWord;
    final userLower = userWord.toLowerCase();
    final correctLower = correct.toLowerCase();

    if (userLower == correctLower) {
      _correctResult = true;
      _correctCount++;
      _playSuccessAnim();
      // می‌توان اینجا XP بدهیم یا آپدیت DB
      Future.delayed(const Duration(seconds: 1), () => _goNext());
    } else {
      _correctResult = false;
      _wrongCount++;
      _playErrorAnim();
      setState(() {});
    }
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_index + 1 < _cards.length) {
      setState(() {
        _index++;
      });
      _preparePuzzle();
    } else {
      // تمام شد
      Spelling_finish = true;
      setState(() {});
    }
  }

  // skip
  void _skip() {
    _goNext();
  }

  // speak
  Future<void> _speak() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.speak(_originalWord);
    } catch (e) {
      // ignore TTS errors
    }
  }

  // animations
  void _playSuccessAnim() {
    _animController.forward().then((_) => _animController.reverse());
  }

  void _playErrorAnim() {
    _animController.forward().then((_) => _animController.reverse());
  }

  // -------------------------
  // UI helpers
  // -------------------------
  Widget _buildPuzzleText() {
    // نمایش حروف: اگر کاراکتر غیر از '_' است، آن را نشان بده؛
    // برای کاراکترهایی که در _puzzleChars برابر '_' هستند، از _userChars مقدار را بگیر
    final spans = <TextSpan>[];
    for (int i = 0; i < _puzzleChars.length; i++) {
      final base = _puzzleChars[i];
      final display = _userChars[i];
      final bool isBlank = base == '_';

      Color color = Colors.black;
      if (_correctResult != null) {
        color = _correctResult! ? Colors.green : Colors.red;
      }

      spans.add(
        TextSpan(
          text: display,
          style: TextStyle(
            fontSize: 38,
            letterSpacing: 2,
            color: isBlank ? color : Colors.black,
            fontWeight: isBlank ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_optionLetters.length, (i) {
        final letter = _optionLetters[i];
        final used = _optionUsed[i];
        return ElevatedButton(
          onPressed: used ? null : () => _selectOption(i),
          style: ElevatedButton.styleFrom(
            backgroundColor: used ? Colors.grey.shade300 : Colors.blue.shade700,
            foregroundColor: used ? Colors.grey.shade600 : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(letter.toUpperCase(), style: const TextStyle(fontSize: 18)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("تمرین املا")),
        body: Center(child: Text("هیچ لغتی برای تمرین موجود نیست")),
      );
    }

    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text("تمرین املا"),
        actions: [
          ?!Spelling_finish
              ? Center(child: Text("${_index + 1} / ${_cards.length}", style: const TextStyle(fontSize: 16)))
              : null,
          const SizedBox(width: 12),
          ?!Spelling_finish ? IconButton(icon: const Icon(Icons.volume_up), onPressed: _speak) : null,
          // IconButton(icon: const Icon(Icons.skip_next), tooltip: "بلدم", onPressed: _skip),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            if (!Spelling_finish) ...[
              const SizedBox(height: 12),

              // پازل با انیمیشن و رنگ‌بندی
              _buildPuzzleText(),

              const SizedBox(height: 14),

              // نمایش معنی و شمارنده درست/غلط
              Text(card.persian, style: const TextStyle(fontSize: 22, color: Colors.grey)),

              const SizedBox(height: 24),

              // گزینه‌ها
              _buildOptionsGrid(),

              const SizedBox(height: 16),

              // کنترل‌ها: پاک کردن یک حرف، بررسی، شمارنده
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next), label: const Text("بلدم")),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _deleteOne,
                    icon: const Icon(Icons.backspace),
                    label: const Text("پاک کن"),
                    //style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  ),

                  // ElevatedButton.icon(
                  //   onPressed: !_userChars.contains('_') ? _checkAnswer : null,
                  //   icon: const Icon(Icons.check),
                  //   label: const Text("بررسی"),
                  //   style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  // ),
                  // const SizedBox(width: 12),
                ],
              ),
              // const SizedBox(height: 18),
              Spacer(),
            ],
            ?Spelling_finish ? Center(child: Text('تمام شد', style: const TextStyle(fontSize: 20))) : null,

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("غلط: $_wrongCount", style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                Text("درست: $_correctCount", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
