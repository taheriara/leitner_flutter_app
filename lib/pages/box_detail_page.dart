// box_detail_page.dart

import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../data/models/flashcard_model.dart';

class BoxDetailPage extends StatefulWidget {
  final int box;
  BoxDetailPage({required this.box});

  @override
  _BoxDetailPageState createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<BoxDetailPage> {
  List<FlashCardModel> cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await DBHelper.instance.cardsByBox(widget.box);
    setState(() => cards = c);
  }

  Future<void> _delete(int id) async {
    await DBHelper.instance.deleteCard(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Box ${widget.box}')),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, i) {
          final c = cards[i];
          return Card(
            child: ListTile(
              title: Text(c.english),
              subtitle: Text(c.persian),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _delete(c.id!),
              ),
            ),
          );
        },
      ),
    );
  }
}
