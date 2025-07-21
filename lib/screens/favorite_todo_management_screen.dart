import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

// お気に入りカテゴリのタイプを定義するEnum
enum FavoriteTodoType {
  daily,
  weekly,
  yearly,
  other, // その他のカスタムタイプ
}

// Enumから表示名への変換
extension FavoriteTodoTypeExtension on FavoriteTodoType {
  String toDisplayName() {
    switch (this) {
      case FavoriteTodoType.daily:
        return 'デイリー';
      case FavoriteTodoType.weekly:
        return 'ウィークリー';
      case FavoriteTodoType.yearly:
        return 'イヤリー';
      case FavoriteTodoType.other:
        return 'その他';
    }
  }

  // 文字列からEnumへの変換
  static FavoriteTodoType fromString(String typeString) {
    switch (typeString) {
      case 'daily':
        return FavoriteTodoType.daily;
      case 'weekly':
        return FavoriteTodoType.weekly;
      case 'yearly':
        return FavoriteTodoType.yearly;
      default:
        return FavoriteTodoType.other;
    }
  }
}

class FavoriteTodoManagementScreen extends StatefulWidget {
  const FavoriteTodoManagementScreen({super.key});

  @override
  State<FavoriteTodoManagementScreen> createState() => _FavoriteTodoManagementScreenState();
}

class _FavoriteTodoManagementScreenState extends State<FavoriteTodoManagementScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーIDが取得できませんでした。')),
        );
      });
    }
  }

  // Firestoreのお気に入りTODOカテゴリコレクション参照を取得するヘルパーメソッド
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

  // カテゴリの追加/編集ダイアログを表示
  Future<void> _showCategoryDialog({DocumentSnapshot? categoryDoc}) async {
    final bool isEditing = categoryDoc != null;
    // categoryDoc.data()がnullの場合に備えて空のマップをデフォルトとして使用
    final Map<String, dynamic> categoryData = categoryDoc?.data() as Map<String, dynamic>? ?? {}; 

    final TextEditingController nameController = TextEditingController(text: categoryData['name'] as String? ?? '');
    FavoriteTodoType selectedType = FavoriteTodoTypeExtension.fromString(categoryData['type'] as String? ?? 'other');
    final TextEditingController orderController = TextEditingController(text: (categoryData['order'] as int?)?.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'カテゴリを編集' : '新しいカテゴリを追加'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'カテゴリ名'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<FavoriteTodoType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'タイプ'),
                    items: FavoriteTodoType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toDisplayName()),
                      );
                    }).toList(),
                    onChanged: (FavoriteTodoType? newValue) {
                      if (newValue != null) {
                        setStateDialog(() {
                          selectedType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: orderController,
                    decoration: const InputDecoration(labelText: '表示順序'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(isEditing ? '更新' : '追加'),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('カテゴリ名を入力してください。')),
                  );
                  return;
                }
                final int order = int.tryParse(orderController.text.trim()) ?? 0;

                try {
                  if (isEditing) {
                    await _getFavoriteTodoCategoriesCollection().doc(categoryDoc!.id).update({
                      'name': nameController.text.trim(),
                      'type': selectedType.toString().split('.').last, // Enum名を文字列として保存
                      'order': order,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('カテゴリを更新しました！')),
                    );
                  } else {
                    await _getFavoriteTodoCategoriesCollection().add({
                      'name': nameController.text.trim(),
                      'type': selectedType.toString().split('.').last,
                      'order': order,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('カテゴリを追加しました！')),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  print('カテゴリ操作エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('カテゴリの操作に失敗しました: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // カテゴリの削除
  Future<void> _deleteCategory(String categoryId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カテゴリを削除'),
          content: const Text('このカテゴリと、紐づくすべてのお気に入りTODOを削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // サブコレクションのTODOも削除（簡易的な実装、トランザクションやバッチ処理が望ましい）
                  final QuerySnapshot todosSnapshot = await _getFavoriteTodoCategoriesCollection()
                      .doc(categoryId)
                      .collection('favoriteTodos')
                      .get();
                  // バッチ処理で効率的に削除
                  final WriteBatch batch = FirebaseFirestore.instance.batch();
                  for (var doc in todosSnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit(); // サブコレクションのTODOを削除

                  await _getFavoriteTodoCategoriesCollection().doc(categoryId).delete(); // カテゴリを削除
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('カテゴリを削除しました！')),
                  );
                } catch (e) {
                  print('カテゴリ削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('カテゴリの削除に失敗しました: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // お気に入りTODOアイテムの追加/編集ダイアログを表示
  Future<void> _showFavoriteTodoItemDialog(String categoryId, {DocumentSnapshot? todoDoc}) async {
    final bool isEditing = todoDoc != null;
    // todoDoc.data()がnullの場合に備えて空のマップをデフォルトとして使用
    final Map<String, dynamic> todoItemData = todoDoc?.data() as Map<String, dynamic>? ?? {}; 

    final TextEditingController textController = TextEditingController(text: todoItemData['text'] as String? ?? '');
    final TextEditingController orderController = TextEditingController(text: (todoItemData['order'] as int?)?.toString() ?? '0');
    final TextEditingController memoController = TextEditingController(text: todoItemData['memo'] as String? ?? ''); // 備考欄のコントローラー

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'お気に入りTODOを編集' : 'お気に入りTODOを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'TODO内容'),
              ),
              const SizedBox(height: 10),
              TextField( // 備考欄を追加
                controller: memoController,
                decoration: const InputDecoration(labelText: '備考'),
                maxLines: 3, // 複数行入力可能に
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: '表示順序'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(isEditing ? '更新' : '追加'),
              onPressed: () async {
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('TODO内容を入力してください。')),
                  );
                  return;
                }
                final int order = int.tryParse(orderController.text.trim()) ?? 0;

                try {
                  if (isEditing) {
                    await _getFavoriteTodoCategoriesCollection()
                        .doc(categoryId)
                        .collection('favoriteTodos')
                        .doc(todoDoc!.id)
                        .update({
                      'text': textController.text.trim(),
                      'order': order,
                      'memo': memoController.text.trim(), // 備考を更新
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('お気に入りTODOを更新しました！')),
                    );
                  } else {
                    await _getFavoriteTodoCategoriesCollection()
                        .doc(categoryId)
                        .collection('favoriteTodos')
                        .add({
                      'text': textController.text.trim(),
                      'order': order,
                      'memo': memoController.text.trim(), // 備考を追加
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('お気に入りTODOを追加しました！')),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  print('お気に入りTODOアイテム操作エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('お気に入りTODOアイテムの操作に失敗しました: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // お気に入りTODOアイテムの削除
  Future<void> _deleteFavoriteTodoItem(String categoryId, String todoId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('お気に入りTODOを削除'),
          content: const Text('このお気に入りTODOを削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _getFavoriteTodoCategoriesCollection()
                      .doc(categoryId)
                      .collection('favoriteTodos')
                      .doc(todoId)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入りTODOを削除しました！')),
                  );
                } catch (e) {
                  print('お気に入りTODOアイテム削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('お気に入りTODOアイテムの削除に失敗しました: $e')),
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
        title: const Text('お気に入りTODO管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(), // 新しいカテゴリを追加
            tooltip: '新しいカテゴリを追加',
          ),
        ],
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _getFavoriteTodoCategoriesCollection().orderBy('order', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Firestore Stream Error (Favorite Categories Management): ${snapshot.error}');
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('お気に入りカテゴリはまだありません。\n右上の＋ボタンで追加してください。'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot categoryDoc = snapshot.data!.docs[index];
                    // categoryDoc.data()がnullの場合に備えて空のマップをデフォルトとして使用
                    final Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>? ?? {}; 
                    final categoryName = categoryData['name'] as String? ?? '無題カテゴリ';
                    final categoryType = categoryData['type'] as String? ?? 'other';
                    final categoryId = categoryDoc.id;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 3.0,
                      child: ExpansionTile(
                        title: Text('$categoryName (${FavoriteTodoTypeExtension.fromString(categoryType).toDisplayName()}タイプ)'),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showCategoryDialog(categoryDoc: categoryDoc),
                              tooltip: 'カテゴリを編集',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteCategory(categoryId),
                              tooltip: 'カテゴリを削除',
                            ),
                          ],
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _showFavoriteTodoItemDialog(categoryId),
                              icon: const Icon(Icons.add),
                              label: const Text('TODOアイテムを追加'),
                            ),
                          ),
                          const Divider(),
                          // お気に入りTODOアイテムのリスト
                          StreamBuilder<QuerySnapshot>(
                            stream: _getFavoriteTodoCategoriesCollection()
                                .doc(categoryId)
                                .collection('favoriteTodos')
                                .orderBy('order', descending: false)
                                .snapshots(),
                            builder: (context, todoSnapshot) {
                              if (todoSnapshot.hasError) {
                                print('Firestore Stream Error (Favorite Todo Items): ${todoSnapshot.error}');
                                return Text('TODOアイテムの読み込みエラー: ${todoSnapshot.error}');
                              }
                              if (todoSnapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (!todoSnapshot.hasData || todoSnapshot.data!.docs.isEmpty) {
                                return const Text('このカテゴリにはTODOアイテムがありません。');
                              }

                              return ListView.builder(
                                shrinkWrap: true, // 内部のListViewなのでshrinkWrapをtrueにする
                                physics: const NeverScrollableScrollPhysics(), // 親のスクロールを優先
                                itemCount: todoSnapshot.data!.docs.length,
                                itemBuilder: (context, todoIndex) {
                                  DocumentSnapshot todoItemDoc = todoSnapshot.data!.docs[todoIndex];
                                  // todoItemDoc.data()がnullの場合に備えて空のマップをデフォルトとして使用
                                  final Map<String, dynamic> todoItemData = todoItemDoc.data() as Map<String, dynamic>? ?? {}; 
                                  final todoText = todoItemData['text'] as String? ?? '無題のTODO';
                                  final todoMemo = todoItemData['memo'] as String? ?? ''; // 備考を取得
                                  final todoItemId = todoItemDoc.id;

                                  return ListTile(
                                    title: Text(todoText),
                                    subtitle: todoMemo.isNotEmpty ? Text('備考: $todoMemo', style: const TextStyle(fontSize: 12, color: Colors.grey)) : null, // 備考を表示
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _showFavoriteTodoItemDialog(categoryId, todoDoc: todoItemDoc),
                                          tooltip: 'TODOアイテムを編集',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20),
                                          onPressed: () => _deleteFavoriteTodoItem(categoryId, todoItemId),
                                          tooltip: 'TODOアイテムを削除',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
