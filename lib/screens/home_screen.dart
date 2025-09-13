import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../models/todo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  // โหมดเลือกหลายรายการ
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(Todo todo) async {
    final editController = TextEditingController(text: todo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขงาน'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'พิมพ์ชื่องาน',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      await context.read<TodoProvider>().editTitle(todo, result);
    }
  }

  void _enterSelectionMode([Todo? first]) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (first?.id != null) _selectedIds.add(first!.id!);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(Todo todo) {
    final id = todo.id;
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final provider = context.read<TodoProvider>();
    final count = _selectedIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรายการที่เลือก?'),
        content: Text('ต้องการลบ $count รายการที่เลือกหรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final items = List<Todo>.from(provider.items);
      for (final t in items) {
        if (t.id != null && _selectedIds.contains(t.id)) {
          await provider.deleteTodo(t);
        }
      }
      if (!mounted) return;
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('เลือกแล้ว ${_selectedIds.length} รายการ')
            : const Text('งานของฉัน'),
        leading: _selectionMode
            ? IconButton(
                tooltip: 'ยกเลิก',
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: 'ลบที่เลือก',
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete),
            ),
          ] else ...[
            IconButton(
              tooltip: 'เลือกรายการ',
              icon: const Icon(Icons.checklist),
              onPressed:
                  provider.items.isEmpty ? null : () => _enterSelectionMode(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final provider = context.read<TodoProvider>();
                if (value == 'clear_all' && provider.items.isNotEmpty) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('ลบทั้งหมด?'),
                      content: const Text('ต้องการลบงานทั้งหมดหรือไม่'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('ลบทั้งหมด'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (!mounted) return;
                    await provider.clearAll();
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Text('ลบทั้งหมด'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'เพิ่มงานใหม่...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) async {
                      final text = _controller.text;
                      _controller.clear();
                      await context.read<TodoProvider>().addTodo(text);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final text = _controller.text;
                    _controller.clear();
                    await context.read<TodoProvider>().addTodo(text);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่ม'),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                    ? const Center(
                        child: Text('ยังไม่มีงาน ใส่ชื่องานด้านบนแล้วกด "เพิ่ม"'),
                      )
                    : ListView.separated(
                        itemCount: provider.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final todo = provider.items[index];
                          final id = todo.id;
                          final selected =
                              id != null && _selectedIds.contains(id);

                          Widget tile = ListTile(
                            leading: _selectionMode
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleSelection(todo),
                                  )
                                : Checkbox(
                                    value: todo.isDone,
                                    onChanged: (_) => context
                                        .read<TodoProvider>()
                                        .toggleDone(todo),
                                  ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color:
                                    todo.isDone ? Colors.grey : null,
                                fontWeight:
                                    selected ? FontWeight.w600 : null,
                              ),
                            ),
                            trailing: _selectionMode
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditDialog(todo),
                                  ),
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(todo);
                              } else {
                                context
                                    .read<TodoProvider>()
                                    .toggleDone(todo);
                              }
                            },
                            onLongPress: () => _enterSelectionMode(todo),
                          );

                          if (_selectionMode) {
                            return tile;
                          } else {
                            return Dismissible(
                              key: ValueKey(id ?? '${todo.title}-$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('ลบงานนี้หรือไม่?'),
                                    content: Text(todo.title),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('ยกเลิก'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('ลบ'),
                                      ),
                                    ],
                                  ),
                                );
                                return ok ?? false;
                              },
                              onDismissed: (_) => context
                                  .read<TodoProvider>()
                                  .deleteTodo(todo),
                              child: tile,
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
