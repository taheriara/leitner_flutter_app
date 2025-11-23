import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:leitner_flutter_app/data/db_helper.dart';
import '../data/models/flashcard_model.dart';
import 'package:leitner_flutter_app/services/tts_service.dart';

class AllCardsPage extends StatefulWidget {
  final int box;
  const AllCardsPage({super.key, required this.box});

  @override
  State<AllCardsPage> createState() => _AllCardsPageState();
}

class _AllCardsPageState extends State<AllCardsPage> {
  final List<FlashCardModel> _cards = [];
  bool _loading = true;
  bool _loadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _ttsService = TTSService();

  // صفحه‌بندی
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCards(reset: true);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadCards(reset: true);
  }

  Future<void> _loadCards({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _cards.clear();
        _hasMore = true;
        _loading = true;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    final db = DBHelper.instance;
    final newCards = await db.pagedCards(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      box: widget.box,
    );

    setState(() {
      if (reset) {
        _cards.clear();
      }
      _cards.addAll(newCards);
      _hasMore = newCards.length == _pageSize;
      _loading = false;
      _loadingMore = false;
      if (!reset && newCards.isNotEmpty) {
        _currentPage++;
      }
    });
  }

  void _editCard(FlashCardModel card) {
    showDialog(
      context: context,
      builder: (context) => EditCardDialog(card: card, onSaved: () => _loadCards(reset: true)),
    );
  }

  void _deleteCard(FlashCardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف لغت"),
        content: Text("آیا از حذف لغت '${card.english}' مطمئنید؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("انصراف")),
          TextButton(
            onPressed: () async {
              final db = DBHelper.instance;
              await db.deleteCard(card.id!);
              if (!mounted) return;
              Navigator.pop(context);
              _loadCards(reset: true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("لغت '${card.english}' حذف شد")));
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _loadMore() {
    if (!_loadingMore && _hasMore) {
      _loadCards(reset: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.box != 0 ? 'جعبه ${widget.box}' : 'همه لغات'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // نوار جستجو
          _cards.isNotEmpty || _searchQuery.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                )
              : Container(),
          // لیست کارت‌ها
          Expanded(
            child: _loading && _cards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? "هیچ لغتی اضافه نشده" : "نتیجه‌ای یافت نشد",
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollEndNotification &&
                          scrollNotification.metrics.pixels == scrollNotification.metrics.maxScrollExtent) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: _cards.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _cards.length) {
                          return _buildLoadMoreIndicator();
                        }
                        final card = _cards[index];
                        return _buildSimpleFlashCard(card, index);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFlashCard(FlashCardModel card, int index) {
    final bool isEvenRow = index % 2 == 0;
    final Color rowColor = isEvenRow ? Colors.white : Colors.grey[200]!;

    Future<void> speakText(String str) async {
      try {
        await _ttsService.speak(str);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در پخش تلفظ'), backgroundColor: Colors.red));
      }
    }

    return Slidable(
      key: Key('card_${card.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _editCard(card),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'ویرایش',
          ),
          SlidableAction(
            onPressed: (context) => _deleteCard(card),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          speakText(card.english);
        },
        child: Container(
          color: rowColor, // رنگ پس‌زمینه برای ردیف‌های یکی در میان
          child: Table(
            columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
            border: TableBorder(
              horizontalInside: BorderSide.none, // حذف خطوط افقی بین ردیف‌ها
              verticalInside: BorderSide(
                color: Colors.grey.shade400, // خط عمودی وسط
                width: 1.0,
              ),
              left: BorderSide.none,
              right: BorderSide.none,
              top: BorderSide.none,
              bottom: BorderSide.none,
            ),
            children: [
              TableRow(
                children: [
                  // سلول فارسی (سمت راست)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Text(
                      card.persian,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  // سلول انگلیسی (سمت چپ)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Text(
                      card.english,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator()
            : _hasMore
            ? ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text('بارگذاری بیشتر'),
              )
            : const Text('همه لغات نمایش داده شد', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

// دیالوگ ویرایش لغت
class EditCardDialog extends StatefulWidget {
  final FlashCardModel card;
  final VoidCallback onSaved;

  const EditCardDialog({super.key, required this.card, required this.onSaved});

  @override
  State<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends State<EditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _englishController = TextEditingController();
  final _persianController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _englishController.text = widget.card.english;
    _persianController.text = widget.card.persian;
  }

  @override
  void dispose() {
    _englishController.dispose();
    _persianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("ویرایش لغت"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _englishController,
              decoration: const InputDecoration(labelText: "لغت انگلیسی", border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "لطفا لغت انگلیسی را وارد کنید";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _persianController,
              decoration: const InputDecoration(labelText: "معنی فارسی", border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "لطفا معنی فارسی را وارد کنید";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("انصراف")),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updatedCard = FlashCardModel(
                id: widget.card.id,
                english: _englishController.text.trim(),
                persian: _persianController.text.trim(),
                box: widget.card.box,
                lastReviewed: widget.card.lastReviewed,
              );

              final db = DBHelper.instance;
              await db.updateCard(updatedCard);

              if (!mounted) return;
              Navigator.pop(context);
              widget.onSaved();

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لغت با موفقیت ویرایش شد")));
            }
          },
          child: const Text("ذخیره"),
        ),
      ],
    );
  }
}
