import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

class FatherFavoriteTodosScreen extends StatefulWidget {
  const FatherFavoriteTodosScreen({super.key});

  @override
  State<FatherFavoriteTodosScreen> createState() => _FatherFavoriteTodosScreenState();
}

class _FatherFavoriteTodosScreenState extends State<FatherFavoriteTodosScreen> {
  final TextEditingController _favoriteInputController = TextEditingController();
  String? _userId; // 現在のユーザーIDを保持

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
    _favoriteInputController.dispose();
    super.dispose();
  }

  // Firestoreのお気に入りTODOコレクション参照を取得するヘルパーメソッド
  CollectionReference<Map<String, dynamic>> _getFavoriteTodoCollection() {
    if (_userId == null) {
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    // 仕様に基づいたコレクションパス: artifacts/{appId}/users/{userId}/fatherFavoriteTodos
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('fatherFavoriteTodos');
  }

  // 新しいお気に入りTODOを追加する
  Future<void> _addFavoriteTodo() async {
    final String favoriteText = _favoriteInputController.text.trim();
    if (favoriteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お気に入りTODOを入力してください。')),
      );
      return;
    }

    try {
      await _getFavoriteTodoCollection().add({
        'text': favoriteText,
        'timestamp': FieldValue.serverTimestamp(), // 作成日時を記録
      });
      _favoriteInputController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お気に入りTODOを追加しました！')),
      );
    } catch (e) {
      print('お気に入りTODO追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入りTODOの追加に失敗しました: $e')),
      );
    }
  }

  // お気に入りTODOを削除する
  Future<void> _deleteFavoriteTodo(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('お気に入りTODOを削除'),
          content: const Text('このお気に入りTODOを削除してもよろしいですか？'),
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
                  await _getFavoriteTodoCollection().doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入りTODOを削除しました！')),
                  );
                } catch (e) {
                  print('お気に入りTODO削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('お気に入りTODOの削除に失敗しました: $e')),
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
        title: const Text('お気に入りを管理'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _favoriteInputController,
                    decoration: const InputDecoration(
                      hintText: '新しいお気に入りTODOを入力',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _addFavoriteTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addFavoriteTodo,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(60, 48),
                  ),
                  child: const Text('追加'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _userId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _getFavoriteTodoCollection()
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
                        return const Center(child: Text('お気に入りTODOはまだありません。'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          String text = data['text'] ?? '無題のお気に入りTODO';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            elevation: 2.0,
                            child: ListTile(
                              title: Text(text),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteFavoriteTodo(doc.id),
                              ),
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
