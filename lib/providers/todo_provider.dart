import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/todo_db.dart';

class TodoProvider extends ChangeNotifier {
  final _db = TodoDB();
  List<Todo> _items = [];
  bool _isLoading = false;

  List<Todo> get items => _items;
  bool get isLoading => _isLoading;

  // โหลดจาก DB ครั้งแรก
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _items = await _db.getTodos();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;
    final todo = Todo(title: title.trim());
    await _db.insertTodo(todo);
    await loadTodos(); // reload เพื่อได้ id ล่าสุด
  }

  Future<void> toggleDone(Todo todo) async {
    final updated = Todo(id: todo.id, title: todo.title, isDone: !todo.isDone);
    await _db.updateTodo(updated);
    final idx = _items.indexWhere((t) => t.id == todo.id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> editTitle(Todo todo, String newTitle) async {
    final updated = Todo(id: todo.id, title: newTitle.trim(), isDone: todo.isDone);
    await _db.updateTodo(updated);
    final idx = _items.indexWhere((t) => t.id == todo.id);
    if (idx != -1) {
      _items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    if (todo.id == null) return;
    await _db.deleteTodo(todo.id!);
    _items.removeWhere((t) => t.id == todo.id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _db.clearAll();
    _items = [];
    notifyListeners();
  }
}
