class DeckModel {
  int? id;
  String name;

  DeckModel({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(id: map['id'], name: map['name']);
  }
}
