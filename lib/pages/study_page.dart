// StudyPage اصلاح شده: کارت صفحه را پر می‌کند و متن راهنما ثابت در پایین است

import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';
import 'package:leitner_flutter_app/services/tts_service.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  _StudyPageState createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<FlashCardModel> _queue = [];
  int _index = 0;
  bool _showBack = false;
  double _dragOffset = 0;
  final _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final due = await DBHelper.instance.dueCards(1);
    due.shuffle();
    setState(() {
      _queue = due;
      _index = 0;
      _showBack = false;
    });
  }

  void _next() {
    setState(() {
      _dragOffset = 0;
      _index++;
      _showBack = false;
    });
  }

  void _markCorrect() async {
    final card = _queue[_index];
    card.box = (card.box + 1).clamp(1, 5);
    card.lastReviewed = DateTime.now().millisecondsSinceEpoch;
    await DBHelper.instance.updateCard(card);
    _next();
  }

  void _markIncorrect() async {
    final card = _queue[_index];
    card.box = 1;
    card.lastReviewed = DateTime.now().millisecondsSinceEpoch;
    await DBHelper.instance.updateCard(card);
    _next();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 120) {
      _markCorrect();
    } else if (_dragOffset < -120) {
      _markIncorrect();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _queue.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرور کارت‌ها'),
        actions: [
          ?_index == _queue.length
              ? null
              : Text(
                  'Card ${_index + 1} / ${_queue.length}',
                  textAlign: TextAlign.center,
                ),
          SizedBox(width: 40),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: done
                  ? Center(
                      child: Text(
                        'مرور امروز تمام شد',
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_index + 1 < _queue.length)
                          _buildCard(_queue[_index + 1], false, 0),
                        Transform.translate(
                          offset: Offset(_dragOffset, 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _showBack = !_showBack),
                            onHorizontalDragUpdate: (d) =>
                                setState(() => _dragOffset += d.delta.dx),
                            onHorizontalDragEnd: _handleDragEnd,
                            child: _buildCard(
                              _queue[_index],
                              _showBack,
                              _dragOffset,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(12),
            //color: Colors.grey.shade200,
            child: Column(
              children: [
                Text(
                  "بزن رو کارت تا ترجمه رو ببینی",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                SizedBox(height: 6),
                Text(
                  "← می‌دانم       نمی‌دانم →",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(FlashCardModel card, bool showBack, double offset) {
    Color textColor = Colors.black;

    if (offset > 0) {
      // فید سبز برای درست
      textColor = Color.lerp(
        Colors.black,
        Colors.green,
        (offset / 120).clamp(0, 1),
      )!;
    } else if (offset < 0) {
      // فید قرمز برای نادرست
      textColor = Color.lerp(
        Colors.black,
        Colors.red,
        (-offset / 120).clamp(0, 1),
      )!;
    }

    return Card(
      elevation: 6,
      child: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              showBack ? card.persian : card.english,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, color: textColor),
            ),
            // if (!showBack) TextButton(onPressed: () => _speakText(card.english), child: Text(card.phonetic ?? '')),
            SizedBox(
              height: 48, // ارتفاع ثابت
              child: !showBack
                  ? TextButton(
                      onPressed:
                          (card.phonetic != null && card.phonetic!.isNotEmpty)
                          ? () => _speakText(card.english)
                          : null,
                      child: Text(
                        card.phonetic != null && card.phonetic!.isNotEmpty
                            ? '${card.phonetic} 🕩'
                            : '',
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakText(String str) async {
    try {
      await _ttsService.speak(str);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در پخش تلفظ'), backgroundColor: Colors.red),
      );
    }
  }
}
