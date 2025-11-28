// هرجا در برنامه می‌خواهی XP بدهی:
// وقتی کاربر یک کارت را درست جواب می‌دهد
// وقتی املا را درست وارد می‌کند
// وقتی یک جلسه مرور را تمام می‌کند

// مثلاً در StudyPage در _markCorrect():
// await DBHelper.instance.addXP(5);

// در SpellingPuzzlePage وقتی املا درست بود:
// if (user == correct) {
//   await DBHelper.instance.addXP(8);
// }

import 'package:flutter/material.dart';
import '../data/db_helper.dart';

class XPPage extends StatefulWidget {
  const XPPage({super.key});

  @override
  State<XPPage> createState() => _XPPageState();
}

class _XPPageState extends State<XPPage> {
  int _xp = 0;
  int _level = 1;
  int _xpForNext = 100;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DBHelper.instance;
    final data = await db.getXPData();
    int xp = data["xp"] as int;
    int level = data["level"] as int;
    int need = 50 + (level - 1) * 20;

    setState(() {
      _xp = xp;
      _level = level;
      _xpForNext = need;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    double progress = _xp / _xpForNext;
    if (progress > 1) progress = 1;

    return Scaffold(
      appBar: AppBar(title: const Text("Your XP & Level")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text("Level $_level", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // XP BAR
            Container(
              height: 28,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey.shade300),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: MediaQuery.of(context).size.width * progress,
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text("$_xp / $_xpForNext XP", style: const TextStyle(fontSize: 20)),

            const SizedBox(height: 40),

            const Text(
              "Gain XP by studying cards, answering spelling puzzles, and reviewing words.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                await DBHelper.instance.addXP(10);
                _load();
              },
              child: const Text("Test: Add 10 XP"),
            ),
          ],
        ),
      ),
    );
  }
}
