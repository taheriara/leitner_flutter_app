import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/data/db_helper.dart';
import '../data/models/flashcard_model.dart';
import 'add_card_page.dart';
import 'study_page.dart';

class DeckPage extends StatefulWidget {
  final int deckId;
  final String deckName;

  const DeckPage({super.key, required this.deckId, required this.deckName});

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  List<FlashCardModel> cards = [];
  int dueCount = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    cards = await DBHelper.instance.cardsByDeck(widget.deckId);
    dueCount = await DBHelper.instance.dueCount(widget.deckId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckName)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCardPage()),
          );
          loadData(); // refresh
        },
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("کارت‌های آماده مرور: $dueCount"),
                ElevatedButton(
                  onPressed: dueCount == 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StudyPage()),
                          );
                        },
                  child: const Text("شروع مطالعه"),
                ),
              ],
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? const Center(child: Text("هیچ کارتی در این دسته نیست"))
                : ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return ListTile(
                        title: Text(card.english),
                        subtitle: Text(card.persian),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
