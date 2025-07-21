import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart'; // ★コメントアウト★ 共有データを受け取るためにインポート

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

class FavoriteWebsiteRegistrationScreen extends StatefulWidget {
  final String? docId; // 編集の場合に渡されるドキュメントID
  final String? initialUrl;
  final String? initialTitle;
  final String? initialMemo;
  final String? initialImageUrl;

  const FavoriteWebsiteRegistrationScreen({
    super.key,
    this.docId,
    this.initialUrl,
    this.initialTitle,
    this.initialMemo,
    this.initialImageUrl,
  });

  @override
  State<FavoriteWebsiteRegistrationScreen> createState() => _FavoriteWebsiteRegistrationScreenState();
}

class _FavoriteWebsiteRegistrationScreenState extends State<FavoriteWebsiteRegistrationScreen> {
  String? _userId;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  String? _imageUrl; // 現在の画像URL
  File? _pickedImage; // 選択された画像ファイル

  final ImagePicker _picker = ImagePicker();

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
      return;
    }

    // 初期値があればコントローラーに設定（編集モードまたは共有からの遷移）
    _urlController.text = widget.initialUrl ?? '';
    _titleController.text = widget.initialTitle ?? '';
    _memoController.text = widget.initialMemo ?? '';
    _imageUrl = widget.initialImageUrl;

    // アプリが起動中に共有データを受け取るリスナー
    // receive_sharing_intent パッケージのメソッドが利用できないため、一時的に無効化
    // ReceiveSharingIntent.getShareTextStream().listen((String value) { 
    //   setState(() {
    //     _urlController.text = value;
    //   });
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('共有されたURLを自動入力しました。')),
    //   );
    // }, onError: (err) {
    //   print("共有データの取得エラー: $err");
    // });

    // アプリが閉じている状態から共有データで起動された場合の処理
    // receive_sharing_intent パッケージのメソッドが利用できないため、一時的に無効化
    // ReceiveSharingIntent.getInitialShareText().then((String? value) { 
    //   if (value != null) {
    //     setState(() {
    //       _urlController.text = value;
    //     });
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('共有されたURLを自動入力しました。')),
    //     );
    //   }
    // });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // Firestoreのお気に入りサイトコレクション参照を取得
  CollectionReference<Map<String, dynamic>> _getFavoriteWebsitesCollection() {
    if (_userId == null) {
      throw Exception("ユーザーIDがnullです。Firestoreにアクセスできません。");
    }
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_userId)
        .collection('favoriteWebsites');
  }

  // 画像を選択
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _imageUrl = null; // 新しい画像が選択されたら既存のURLをクリア
      });
    }
  }

  // 画像をFirebase Storageにアップロード
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final String fileName = '${_userId}/favorite_website_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('画像アップロードエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像のアップロードに失敗しました: $e')),
      );
      return null;
    }
  }

  // お気に入りサイトを保存
  Future<void> _saveFavoriteWebsite() async {
    final String url = _urlController.text.trim();
    final String title = _titleController.text.trim();
    final String memo = _memoController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを入力してください。')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存中...')),
    );

    String? finalImageUrl = _imageUrl; // 既存の画像URLを保持

    // 新しい画像が選択されていればアップロード
    if (_pickedImage != null) {
      finalImageUrl = await _uploadImage(_pickedImage!);
      if (finalImageUrl == null) {
        return; // アップロード失敗したら処理を中断
      }
    }

    try {
      if (widget.docId == null) {
        // 新規登録
        await _getFavoriteWebsitesCollection().add({
          'url': url,
          'title': title.isNotEmpty ? title : '無題のサイト',
          'memo': memo,
          'imageUrl': finalImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お気に入りサイトを登録しました！')),
        );
      } else {
        // 編集
        await _getFavoriteWebsitesCollection().doc(widget.docId).update({
          'url': url,
          'title': title.isNotEmpty ? title : '無題のサイト',
          'memo': memo,
          'imageUrl': finalImageUrl, // 画像が削除された場合はnullになる
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お気に入りサイトを更新しました！')),
        );
      }
      Navigator.of(context).pop(); // 前の画面に戻る
    } catch (e) {
      print('お気に入りサイト保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入りサイトの保存に失敗しました: $e')),
      );
    }
  }

  // 画像を拡大表示
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? 'お気に入りサイト登録' : 'お気に入りサイト編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFavoriteWebsite,
            tooltip: '保存',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: '例: https://www.google.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'サイト名',
                hintText: '例: Google',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ',
                hintText: 'このサイトに関するメモ',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_pickedImage != null || _imageUrl != null ? '画像を変更' : '画像を添付'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 選択された画像または既存の画像URLを表示
            if (_pickedImage != null)
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showImageDialog(_pickedImage!.path), // Fileパスを渡す
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            _pickedImage!,
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                      onPressed: () {
                        setState(() {
                          _pickedImage = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showImageDialog(_imageUrl!),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.0),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _imageUrl!,
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                      onPressed: () async {
                        // Firebase Storageから画像を削除
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('画像を削除'),
                              content: const Text('この画像を削除してもよろしいですか？'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('キャンセル'),
                                  onPressed: () => Navigator.of(context).pop(false),
                                ),
                                TextButton(
                                  child: const Text('削除'),
                                  onPressed: () => Navigator.of(context).pop(true),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmDelete == true) {
                          try {
                            if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                              await FirebaseStorage.instance.refFromURL(_imageUrl!).delete();
                            }
                            await _getFavoriteWebsitesCollection().doc(widget.docId).update({'imageUrl': FieldValue.delete()});
                            setState(() {
                              _imageUrl = null; // UIから画像を削除
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('画像を削除しました！')),
                            );
                          } catch (e) {
                            print('画像削除エラー: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('画像の削除に失敗しました: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
