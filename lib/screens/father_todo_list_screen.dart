import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fujitake_app/screens/favorite_todo_management_screen.dart';
import 'package:fujitake_app/screens/todo_detail_screen.dart';
import 'package:fujitake_app/utils/date_extensions.dart'; // ★重要★ このインポートが正しいことを確認
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

class FatherTodoListScreen extends StatefulWidget {
  const FatherTodoListScreen({super.key});

  @override
  State<FatherTodoListScreen> createState() => _FatherTodoListScreenState();
}

class _FatherTodoListScreenState extends State<FatherTodoListScreen> {
  final TextEditingController _todoInputController = TextEditingController();
  String? _userId;

  DateTime? _selectedDueDate; 
  final TextEditingController _memoInputController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーIDが取得できませんでした。Firebase認証を確認してください。')),
        );
      });
    }
  }

  @override
  void dispose() {
    _todoInputController.dispose();
    _memoInputController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _getTodoCollection() {
    if (_userId == null) {
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('fatherTodos');
  }

  CollectionReference<Map<String, dynamic>> _getFavoriteTodoCategoriesCollection() {
    if (_userId == null) {
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('favoriteTodoCategories');
  }

  // 日付と時刻をまとめて設定するピッカーを表示
  Future<void> _selectDateTime(BuildContext context, {DateTime? initialDateTime}) async {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now().subtract(const Duration(days: 365 * 5)),
      maxTime: DateTime.now().add(const Duration(days: 365 * 10)),
      onConfirm: (date) {
        setState(() {
          _selectedDueDate = date;
        });
      },
      currentTime: initialDateTime ?? DateTime.now(),
      locale: LocaleType.jp, // 日本語ロケールを設定
    );
  }

  // 新しいTODOを追加する
  Future<void> _addTodo() async {
    final String todoText = _todoInputController.text.trim();
    final String memoText = _memoInputController.text.trim();

    if (todoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TODOを入力してください。')),
      );
      return;
    }

    try {
      await _getTodoCollection().add({
        'text': todoText,
        'isCompleted': false,
        'timestamp': FieldValue.serverTimestamp(),
        'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
        'memo': memoText,
        'imageUrl': null,
      });
      _todoInputController.clear();
      _memoInputController.clear();
      setState(() {
        _selectedDueDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TODOを追加しました！')),
      );
    } catch (e) {
      print('TODO追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODOの追加に失敗しました: $e')),
      );
    }
  }

  // TODOの完了状態を切り替える
  Future<void> _toggleTodoStatus(String docId, bool currentStatus) async {
    try {
      await _getTodoCollection().doc(docId).update({
        'isCompleted': !currentStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODOを${currentStatus ? '未完了' : '完了'}にしました！')),
      );
    } catch (e) {
      print('TODO状態更新エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODOの状態更新に失敗しました: $e')),
      );
    }
  }

  // TODOを削除する
  Future<void> _deleteTodo(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('TODOを削除'),
          content: const Text('このTODOを削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final docSnapshot = await _getTodoCollection().doc(docId).get();
                  final data = docSnapshot.data() as Map<String, dynamic>? ?? {};
                  final imageUrl = data['imageUrl'] as String?;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    try {
                      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                    } catch (storageError) {
                      print('Storageからの画像削除エラー: $storageError');
                    }
                  }

                  await _getTodoCollection().doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('TODOを削除しました！')),
                  );
                } catch (e) {
                  print('TODO削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('TODOの削除に失敗しました: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTodoDialog(DocumentSnapshot todoDoc) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoDetailScreen(todoDocId: todoDoc.id),
      ),
    );
  }

  Future<void> _showFavoriteAddDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('お気に入りTODOを一括登録'),
          content: StreamBuilder<QuerySnapshot>(
            stream: _getFavoriteTodoCategoriesCollection().orderBy('order', descending: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Firestore Stream Error (Favorite Categories): ${snapshot.error}');
                return Text('エラー: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('お気に入りカテゴリがありません。\n管理画面で追加してください。');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!.docs.map((doc) {
                  final categoryData = doc.data() as Map<String, dynamic>? ?? {}; 
                  final categoryName = categoryData['name'] as String? ?? '無題カテゴリ';
                  final categoryType = categoryData['type'] as String? ?? 'other';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _addFavoriteTodos(doc.id, categoryType);
                      },
                      child: Text(categoryName),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addFavoriteTodos(String categoryId, String categoryType) async {
    final QuerySnapshot favoriteTodosSnapshot = await _getFavoriteTodoCategoriesCollection()
        .doc(categoryId)
        .collection('favoriteTodos')
        .orderBy('order', descending: false)
        .get();

    if (favoriteTodosSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このお気に入りカテゴリにはTODOがありません。')),
      );
      return;
    }

    DateTime now = DateTime.now();
    DateTime calculatedDueDate;

    switch (categoryType) {
      case 'daily':
        calculatedDueDate = now.endOfDay();
        break;
      case 'weekly':
        calculatedDueDate = now.nextSunday().endOfDay();
        break;
      case 'yearly':
        calculatedDueDate = DateTime(now.year + 1, now.month, now.day).subtract(const Duration(days: 1)).endOfDay();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('不明なカテゴリタイプが設定されています。')),
        );
        return;
    }

    try {
      for (var doc in favoriteTodosSnapshot.docs) {
        final todoItemData = doc.data() as Map<String, dynamic>? ?? {}; 
        final todoText = todoItemData['text'] as String? ?? '無題のTODO';
        final todoMemo = todoItemData['memo'] as String? ?? '';
        await _getTodoCollection().add({
          'text': todoText,
          'isCompleted': false,
          'timestamp': FieldValue.serverTimestamp(),
          'dueDate': Timestamp.fromDate(calculatedDueDate),
          'memo': todoMemo,
          'imageUrl': null,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入りTODOを一括登録しました！')),
      );
    } catch (e) {
      print('お気に入りTODO一括登録エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入りTODOの一括登録に失敗しました: $e')),
      );
    }
  }

  Future<void> _bulkDeleteAllTodos() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('すべてのTODOを削除'),
          content: const Text('すべてのTODOを削除してもよろしいですか？この操作は元に戻せません。'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('すべて削除'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final QuerySnapshot todosSnapshot = await _getTodoCollection().get();
                  if (todosSnapshot.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('削除するTODOはありません。')),
                    );
                    return;
                  }

                  final WriteBatch batch = FirebaseFirestore.instance.batch();
                  for (var doc in todosSnapshot.docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final imageUrl = data['imageUrl'] as String?;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      try {
                        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                      } catch (storageError) {
                        print('Storageからの画像削除エラー (一括削除時): $storageError');
                      }
                    }
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('すべてのTODOを削除しました！')),
                  );
                } catch (e) {
                  print('TODO一括削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('すべてのTODOの削除に失敗しました: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お父さんのTODOリスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoriteTodoManagementScreen()),
              );
            },
            tooltip: 'お気に入りTODOを管理',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _bulkDeleteAllTodos,
            tooltip: 'すべてのTODOを削除',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _todoInputController,
                  decoration: const InputDecoration(
                    hintText: '新しいTODOを入力',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onSubmitted: (_) => _addTodo(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoInputController,
                  decoration: const InputDecoration(
                    hintText: '備考（メモ）',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  maxLines: 2,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDueDate == null
                            ? '期限日: 未設定'
                            : '期限日: ${DateFormat('MM/dd HH:mm').format(_selectedDueDate!)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDateTime(context, initialDateTime: _selectedDueDate),
                      tooltip: '期限日を設定',
                    ),
                    if (_selectedDueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                        tooltip: '期限日をクリア',
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTodo,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 48),
                      ),
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _showFavoriteAddDialog,
                    icon: const Icon(Icons.star),
                    label: const Text('お気に入りから一括登録'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _userId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _getTodoCollection()
                        .orderBy('dueDate', descending: false)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        print('Firestore Stream Error: ${snapshot.error}');
                        return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('TODOはまだありません。'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {}; 
                          bool isCompleted = data['isCompleted'] as bool? ?? false;
                          String text = data['text'] as String? ?? '無題のTODO';
                          Timestamp? dueDateTimestamp = data['dueDate'] as Timestamp?;
                          String? dueDateText;
                          if (dueDateTimestamp != null) {
                            dueDateText = DateFormat('yyyy/MM/dd HH:mm').format(dueDateTimestamp.toDate());
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            elevation: 2.0,
                            child: ListTile(
                              leading: Checkbox(
                                value: isCompleted,
                                onChanged: (bool? newValue) {
                                  _toggleTodoStatus(doc.id, isCompleted);
                                },
                              ),
                              title: Text(
                                text,
                                style: TextStyle(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: isCompleted ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: dueDateText != null
                                  ? Text('期限: $dueDateText')
                                  : null,
                              onLongPress: () => _deleteTodo(doc.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TodoDetailScreen(todoDocId: doc.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
