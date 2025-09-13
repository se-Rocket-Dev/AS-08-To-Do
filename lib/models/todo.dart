class Todo {
  final int? id;
  String title;
  bool isDone;

  Todo({this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_done': isDone ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
    );
  }
}
