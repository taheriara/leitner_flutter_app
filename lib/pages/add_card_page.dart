// add_card_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/services/tts_service.dart';
import '../services/pronunciation_service.dart';
import 'package:translator/translator.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';

class AddCardPage extends StatefulWidget {
  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _englishController = TextEditingController();
  final _persianController = TextEditingController();
  bool _autoTranslate = true;
  Timer? _debounce;
  bool _isTranslating = false;
  final GoogleTranslator _translator = GoogleTranslator();
  final _ttsService = TTSService();
  // bool _isSpeaking = false;
  final _pronunciationService = PronunciationService();
  String? _phoneticText;
  // bool _isGettingPronunciation = false;

  @override
  void initState() {
    super.initState();
    _englishController.addListener(_onEnglishChanged);
  }

  void _onEnglishChanged() {
    if (!_autoTranslate) return;
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 800), () async {
      final text = _englishController.text.trim();
      if (text.isEmpty) return;
      if (_persianController.text.trim().isNotEmpty) return;
      setState(() => _isTranslating = true);
      try {
        String tr = await _translator.translate(text, to: 'fa').then((res) => res.text);
        if (_englishController.text.trim() == text) {
          _persianController.text = tr;
          _speakText();
          _getPronunciation();
        }
      } catch (e) {}
      if (mounted) setState(() => _isTranslating = false);
    });
  }

  @override
  void dispose() {
    _englishController.dispose();
    _persianController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearAll() {
    _englishController.clear();
    _persianController.clear();
    _phoneticText = '';
    setState(() {});
  }

  Future<void> _saveCard() async {
    final eng = _englishController.text.trim();
    final fa = _persianController.text.trim();
    if (eng.isEmpty || fa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لطفاً هر دو قسمت را پر کنید')));
      return;
    }
    final card = FlashCardModel(english: eng, persian: fa, phonetic: _phoneticText);
    await DBHelper.instance.insertCard(card);
    //Navigator.pop(context);
    _clearAll();
  }

  Future<void> _speakText() async {
    if (_englishController.text.isEmpty) return;

    // setState(() {
    //   _isSpeaking = true;
    // });

    try {
      await _ttsService.speak(_englishController.text);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در پخش تلفظ'), backgroundColor: Colors.red));
    } finally {
      // setState(() {
      //   _isSpeaking = false;
      // });
    }
  }

  Future<void> _getPronunciation() async {
    if (_englishController.text.isEmpty) return;
    try {
      final pronunciation = await _pronunciationService.getPronunciation(_englishController.text.trim());

      if (pronunciation != null) {
        setState(() {
          _phoneticText = pronunciation.phoneticText;
          //  _audioUrl = pronunciation.audioUrl;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اضافه کردن کارت')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _englishController,
                  decoration: InputDecoration(
                    labelText: 'English (front)',
                    hintText: 'enter English word or phrase',
                    suffixIcon: !_isTranslating && _englishController.text.isEmpty
                        ? null
                        : GestureDetector(
                            onTap: () async {
                              _clearAll();
                            },
                            child: Icon(_isTranslating ? null : Icons.clear, color: Colors.grey),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _persianController,
                  decoration: InputDecoration(
                    labelText: 'Persian (back)',
                    hintText: 'translation will appear here',
                    suffixIcon: !_isTranslating && _englishController.text.isEmpty
                        ? null
                        : GestureDetector(
                            onTap: () async {
                              setState(() {
                                _persianController.clear();
                              });
                            },
                            child: Icon(_isTranslating ? null : Icons.clear, color: Colors.grey),
                          ),
                  ),
                ),
                if (_isTranslating)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Checkbox(value: _autoTranslate, onChanged: (v) => setState(() => _autoTranslate = v ?? true)),
                Expanded(child: Text('پر کردن خودکار ترجمه با استفاده از Google Translate (اینترنت لازم است)')),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'ترجمه دستی',
                  onPressed: () async {
                    final text = _englishController.text.trim();
                    if (text.isEmpty) return;
                    setState(() => _isTranslating = true);
                    try {
                      final tr = await _translator.translate(text, to: 'fa').then((res) => res.text);
                      _persianController.text = tr;
                      _speakText();
                      _getPronunciation();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ترجمه')));
                    }
                    if (mounted) setState(() => _isTranslating = false);
                  },
                ),
              ],
            ),
            SizedBox(height: 14),
            // TextButton(
            //   onPressed: () => _speakText(),
            //   child: Text(_phoneticText != null && _phoneticText!.isNotEmpty ? '$_phoneticText 🕩' : ''),
            // ),
            SizedBox(
              height: 38, // ارتفاع ثابت
              child: TextButton(
                onPressed: (_phoneticText != null && _phoneticText!.isNotEmpty) ? () => _speakText() : null,
                child: Text(
                  _phoneticText != null && _phoneticText!.isNotEmpty ? '🔉  $_phoneticText' : '',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(onPressed: _saveCard, icon: Icon(Icons.save), label: Text('ذخیره')),
          ],
        ),
      ),
    );
  }
}

//--*-*-*-*--*-*-*-*-*-*-*-*

// import 'package:flutter/material.dart';
// import 'package:leitner_flutter_app/data/db_helper.dart';
// import '../data/models/flashcard_model.dart';

// class AddCardPage extends StatefulWidget {

//   const AddCardPage({super.key});

//   @override
//   State<AddCardPage> createState() => _AddCardPageState();
// }

// class _AddCardPageState extends State<AddCardPage> {
//   final engCtrl = TextEditingController();
//   final perCtrl = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("افزودن کارت")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: engCtrl,
//               decoration: const InputDecoration(
//                 labelText: "لغت انگلیسی",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: perCtrl,
//               decoration: const InputDecoration(
//                 labelText: "ترجمه فارسی",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 if (engCtrl.text.trim().isEmpty || perCtrl.text.trim().isEmpty)
//                   return;

//                 await DBHelper.instance.insertCard(
//                   FlashCardModel(
//                     english: engCtrl.text.trim(),
//                     persian: perCtrl.text.trim(),
//                     box: 1,
//                     lastReviewed: 0,
//                     deckId: 1,
//                   ),
//                 );

//                 Navigator.pop(context);
//               },
//               child: const Text("ذخیره"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
