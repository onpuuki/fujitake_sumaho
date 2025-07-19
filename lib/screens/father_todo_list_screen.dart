import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用に追加

// アプリケーションIDは仕様の例に基づきハードコード。
// 実際のアプリでは、環境変数や設定ファイルから取得することが推奨されます。
const String _appId = 'fujitake_family_app';

class FatherTodoListScreen extends StatefulWidget {
  const FatherTodoListScreen({super.key});

  @override
  State<FatherTodoListScreen> createState() => _FatherTodoListScreenState();
}

class _FatherTodoListScreenState extends State<FatherTodoListScreen> {
  final TextEditingController _todoInputController = TextEditingController();
  String? _userId; // 現在のユーザーIDを保持
  DateTime? _selectedDueDate; // 選択された期限日

  @override
  void initState() {
    super.initState();
    // Firebase Authから現在のユーザーIDを取得
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      // ユーザーIDが取得できない場合はエラーメッセージを表示（main.dartで匿名認証されているはずですが念のため）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーIDが取得できませんでした。Firebase認証を確認してください。')),
        );
      });
    }
  }

  @override
  void dispose() {
    _todoInputController.dispose(); // コントローラーを破棄してメモリリークを防ぐ
    super.dispose();
  }

  // Firestoreのコレクション参照を取得するヘルパーメソッド
  CollectionReference<Map<String, dynamic>> _getTodoCollection() {
    if (_userId == null) {
      // ユーザーIDがない場合はFirestore操作ができないため例外をスロー
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    // 仕様に基づいたコレクションパス: artifacts/{appId}/users/{userId}/fatherTodos
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('fatherTodos');
  }

  // 日付ピッカーを表示して期限日を選択
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(), // 初期値は現在の日付または選択済みの期限日
      firstDate: DateTime.now(), // 選択可能な最初の日付は今日
      lastDate: DateTime(2101), // 選択可能な最後の日付
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  // 新しいTODOを追加する
  Future<void> _addTodo() async {
    final String todoText = _todoInputController.text.trim();
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
        'timestamp': FieldValue.serverTimestamp(), // 作成日時を記録
        'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null, // 期限日を追加
      });
      _todoInputController.clear(); // 入力フィールドをクリア
      setState(() {
        _selectedDueDate = null; // 期限日をリセット
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
    // 削除確認ダイアログを表示
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
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () async {
                Navigator.of(context).pop(); // ダイアログを閉じる
                try {
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

  // お気に入りTODOを一括登録する
  Future<void> _bulkAddFavoriteTodos() async {
    // ここではサンプルとしてハードコードされたTODOを登録します。
    // 実際には、別の画面で定義された「お気に入り」テンプレートから取得します。
    final List<Map<String, dynamic>> favoriteTodos = [
      {'text': '毎月の請求書支払い', 'dueDate': DateTime.now().add(const Duration(days: 30))},
      {'text': '毎週のゴミ出し', 'dueDate': DateTime.now().add(const Duration(days: 7))},
      {'text': '毎日のルーティン（朝）', 'dueDate': DateTime.now().add(const Duration(days: 1))},
      {'text': '毎日のルーティン（夜）', 'dueDate': DateTime.now().add(const Duration(days: 1))},
    ];

    try {
      for (var todo in favoriteTodos) {
        await _getTodoCollection().add({
          'text': todo['text'],
          'isCompleted': false,
          'timestamp': FieldValue.serverTimestamp(),
          'dueDate': Timestamp.fromDate(todo['dueDate']),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お気に入りTODOを一括登録しました！')),
      );
    } catch (e) {
      print('お気に入りTODO一括登録エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入りTODOの一括登録に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お父さんのTODOリスト'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _todoInputController,
                        decoration: InputDecoration(
                          hintText: '新しいTODOを入力',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          // 期限日が表示されるようにする
                          suffixIcon: _selectedDueDate == null
                              ? null
                              : TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDueDate = null; // 期限日をクリア
                                    });
                                  },
                                  child: Text(
                                    DateFormat('MM/dd').format(_selectedDueDate!),
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                        ),
                        onSubmitted: (_) => _addTodo(), // Enterキーで追加
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 日付ピッカーボタン
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDueDate(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTodo,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 48), // ボタンの最小サイズを設定
                      ),
                      child: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // お気に入りから一括登録ボタン
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _bulkAddFavoriteTodos,
                    icon: const Icon(Icons.star),
                    label: const Text('お気に入りから一括登録'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // StreamBuilderでFirestoreのリアルタイム更新をリッスン
            child: _userId == null
                ? const Center(child: CircularProgressIndicator()) // ユーザーID取得中はローディング表示
                : StreamBuilder<QuerySnapshot>(
                    stream: _getTodoCollection()
                        // 期限日がnullでないものを先に、期限日順（昇順）、その後作成日時順（降順）でソート
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

                      // TODOリストの表示 (FlatListの代わりにListView.builderを使用)
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          bool isCompleted = data['isCompleted'] ?? false;
                          String text = data['text'] ?? '無題のTODO';
                          Timestamp? dueDateTimestamp = data['dueDate'] as Timestamp?;
                          String? dueDateText;
                          if (dueDateTimestamp != null) {
                            // 日付と時刻をフォーマット
                            dueDateText = DateFormat('MM/dd HH:mm').format(dueDateTimestamp.toDate());
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
                                  : null, // 期限日を表示
                              // 長押しで削除確認ダイアログを表示
                              onLongPress: () => _deleteTodo(doc.id),
                              // TODO: タップで詳細画面に遷移するロジックをここに追加
                              // onTap: () {
                              //   Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //       builder: (context) => FatherTodoDetailScreen(todoId: doc.id),
                              //     ),
                              //   );
                              // },
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
