// flashcard_model.dart
// Model class for Leitner Flashcards

class FlashCardModel {
  int? id;
  int deckId; // برای دسته بندی لغات که فعلا استفاده نشده است
  String english;
  String persian;
  String? phonetic;
  int box; // 1..5
  int lastReviewed; // epoch milliseconds

  FlashCardModel({
    this.id,
    this.deckId = 1,
    required this.english,
    required this.persian,
    this.phonetic,
    this.box = 1,
    int? lastReviewed,
  }) : lastReviewed = lastReviewed ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'english': english,
      'persian': persian,
      'phonetic': phonetic,
      'box': box,
      'lastReviewed': lastReviewed,
    };
  }

  factory FlashCardModel.fromMap(Map<String, dynamic> map) {
    return FlashCardModel(
      id: map['id'] as int?,
      deckId: map['deckId'] as int,
      english: map['english'] as String,
      persian: map['persian'] as String,
      phonetic: map['phonetic'] as String?,
      box: map['box'] as int,
      lastReviewed: map['lastReviewed'] as int,
    );
  }
}
