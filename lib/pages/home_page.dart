// home_page.dart

import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/pages/all_cards_page.dart';
import 'package:leitner_flutter_app/pages/spelling_practice_page.dart';
import 'package:leitner_flutter_app/pages/spelling_puzzle_page.dart';
import 'package:leitner_flutter_app/pages/xp_page.dart';
import '../data/db_helper.dart';
import 'add_card_page.dart';
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
        title: Text(boxNumber != 0 ? 'Box ${boxNumber}' : 'همه لغات'),
        subtitle: Text(
          boxNumber != 0
              ? '${counts[boxNumber - 1]} cards'
              : '${counts.sum().toString()} cards',
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AllCardsPage(box: boxNumber)),
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
        title: Text('Leitner'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note),
            tooltip: 'Spelling',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SpellingPuzzlePage()),
              );
            },
          ),
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
        // leading: IconButton(
        //   icon: const Icon(Icons.menu),
        //   tooltip: 'Menu Icon',
        //   onPressed: () {

        //   },
        // ),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // بخش بالای دراور
            CustomDrawerHeader(),

            // لیست گزینه‌ها
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text(' وارد کردن لغات از فایل '),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text(' ذخیره لغات در فایل '),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('لغات بایگانی شده'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('راهنما'),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // متن پایین صفحه
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "h.taheriara@gmail.com\n", //❤️
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        // backgroundColor: const Color.fromRGBO(82, 170, 94, 1.0),
        tooltip: 'Add Card',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCardPage()),
          );
          await _loadCounts();
        },
        label: const Text('اضافه کردن کارت'),
        icon: const Icon(Icons.add, size: 28),
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
            _boxCard(0),

            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await DBHelper.instance.shiftReviewDates(1);
                await _loadCounts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("آخرین مرور به یک روز قبل تنظیم شد"),
                  ),
                );
              },
              icon: Icon(Icons.calendar_month),
              label: Text('تنظیم به یک روز قبل'),
            ),
            // ElevatedButton(
            //   child: Text("XP & Level"),
            //   onPressed: () {
            //     Navigator.push(context, MaterialPageRoute(builder: (_) => const XPPage()));
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

extension ListSum on List<int> {
  int sum() => this.fold(0, (prev, element) => prev + element);
}

class CustomDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close),
            ),
            Container(
              // Customize the height, color, and other properties as needed
              height: 190.0,
              //color: Colors.blue,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Leitner v1.0',
                      style: TextStyle(color: Colors.black, fontSize: 32.0),
                    ),
                    Text(
                      'Clean App',
                      style: TextStyle(color: Colors.black, fontSize: 14.0),
                    ),
                    Image.asset('assets/images/box.gif', width: 170),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
