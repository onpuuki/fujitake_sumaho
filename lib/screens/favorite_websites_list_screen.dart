import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // URLを開くためにインポート
import 'package:fujitake_app/screens/favorite_website_registration_screen.dart'; // 登録画面をインポート
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storageをインポート

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

class FavoriteWebsitesListScreen extends StatefulWidget {
  const FavoriteWebsitesListScreen({super.key});

  @override
  State<FavoriteWebsitesListScreen> createState() => _FavoriteWebsitesListScreenState();
}

class _FavoriteWebsitesListScreenState extends State<FavoriteWebsitesListScreen> {
  String? _userId;

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

  // Firestoreのお気に入りサイトコレクション参照を取得するヘルパーメソッド
  CollectionReference<Map<String, dynamic>> _getFavoriteWebsitesCollection() {
    if (_userId == null) {
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    // コレクションパス: artifacts/{appId}/users/{userId}/favoriteWebsites
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('favoriteWebsites');
  }

  // URLを開く
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URLを開けませんでした: $urlString')),
      );
    }
  }

  // お気に入りサイトを削除する
  Future<void> _deleteFavoriteWebsite(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('お気に入りサイトを削除'),
          content: const Text('このお気に入りサイトを削除してもよろしいですか？'),
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
                  // 画像URLがあればStorageからも削除
                  final docSnapshot = await _getFavoriteWebsitesCollection().doc(docId).get();
                  final data = docSnapshot.data() as Map<String, dynamic>? ?? {};
                  final imageUrl = data['imageUrl'] as String?;
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    try {
                      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                    } catch (storageError) {
                      print('Storageからの画像削除エラー: $storageError');
                    }
                  }

                  await _getFavoriteWebsitesCollection().doc(docId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('お気に入りサイトを削除しました！')),
                  );
                } catch (e) {
                  print('お気に入りサイト削除エラー: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('お気に入りサイトの削除に失敗しました: $e')),
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
        title: const Text('お気に入りサイト'),
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _getFavoriteWebsitesCollection().orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Firestore Stream Error (Favorite Websites): ${snapshot.error}');
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('お気に入りサイトはまだありません。\n右下の＋ボタンで追加してください。'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final String title = data['title'] as String? ?? '無題のサイト';
                    final String url = data['url'] as String? ?? '';
                    final String? imageUrl = data['imageUrl'] as String?;
                    final String memo = data['memo'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      elevation: 2.0,
                      child: ListTile(
                        leading: imageUrl != null && imageUrl.isNotEmpty
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                                    },
                                  ),
                                ),
                              )
                            : const Icon(Icons.link, size: 40, color: Colors.blueGrey), // 画像がない場合のアイコン
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(url, style: const TextStyle(fontSize: 12, color: Colors.blue)),
                            if (memo.isNotEmpty) Text('メモ: $memo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => _launchUrl(url), // タップでURLを開く
                        onLongPress: () => _deleteFavoriteWebsite(doc.id), // 長押しで削除
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // 編集画面へ遷移
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FavoriteWebsiteRegistrationScreen(
                                  docId: doc.id,
                                  initialUrl: url,
                                  initialTitle: title,
                                  initialMemo: memo,
                                  initialImageUrl: imageUrl,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 登録画面へ遷移（新規登録）
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoriteWebsiteRegistrationScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
