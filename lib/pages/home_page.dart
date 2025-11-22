// home_page.dart

import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/pages/all_cards_page.dart';
import '../data/db_helper.dart';
import 'add_card_page.dart';
import 'box_detail_page.dart';
import 'study_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> counts = [0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final all = await DBHelper.instance.cardsByDeck(1);
    final newCounts = [0, 0, 0, 0, 0];
    for (var c in all) {
      final idx = (c.box - 1).clamp(0, 4);
      newCounts[idx]++;
    }
    setState(() => counts = newCounts);
  }

  Widget _boxCard(int boxNumber) {
    return Card(
      child: ListTile(
        title: Text('Box $boxNumber'),
        subtitle: Text('${counts[boxNumber - 1]} card'),
        trailing: Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BoxDetailPage(box: boxNumber)),
          );
          await _loadCounts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leitner v1.0'),
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow),
            tooltip: 'Study',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudyPage()),
              );
              await _loadCounts();
            },
          ),
          SizedBox(width: 30),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            _boxCard(1),
            _boxCard(2),
            _boxCard(3),
            _boxCard(4),
            _boxCard(5),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddCardPage()),
                );
                await _loadCounts();
              },
              icon: Icon(Icons.add),
              label: Text('اضافه کردن کارت'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await DBHelper.instance.shiftReviewDates(1);

                await _loadCounts();
              },
              icon: Icon(Icons.calendar_month),
              label: Text('تنظیم به یک روز قبل'),
            ),
            ElevatedButton(
              child: const Text("همه لغات"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllCardsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
