import 'package:flutter/material.dart';
import 'package:leitner_flutter_app/data/db_helper.dart';
import '../data/models/deck_model.dart';

class AddDeckPage extends StatefulWidget {
  const AddDeckPage({super.key});

  @override
  State<AddDeckPage> createState() => _AddDeckPageState();
}

class _AddDeckPageState extends State<AddDeckPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ساخت دسته جدید")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "نام دسته",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                await DBHelper.instance.insertDeck(
                  DeckModel(name: controller.text.trim()),
                );

                Navigator.pop(context);
              },
              child: const Text("ذخیره"),
            ),
          ],
        ),
      ),
    );
  }
}
