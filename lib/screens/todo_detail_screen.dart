import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // 画像ピッカーをインポート
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storageをインポート
import 'dart:io'; // File操作のためにインポート
import 'package:fujitake_app/utils/date_extensions.dart'; // 共通のDateTime拡張をインポート
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'; // ★追加★

// アプリケーションIDは仕様の例に基づきハードコード。
const String _appId = 'fujitake_family_app';

// DateTimeExtensionはdate_extensions.dartに移動しました。

class TodoDetailScreen extends StatefulWidget {
  final String todoDocId; // 編集するTODOのドキュメントID

  const TodoDetailScreen({super.key, required this.todoDocId});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  String? _userId;
  DocumentSnapshot? _todoDoc; // TODOの最新データを保持
  bool _isEditing = false; // 編集モードかどうか
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime? _selectedDueDate;
  String? _imageUrl; // 画像URLを保持

  final ImagePicker _picker = ImagePicker(); // ImagePickerのインスタンス

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
      return;
    }
    _fetchTodoDetails(); // TODOの詳細データを取得
  }

  @override
  void dispose() {
    _textController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // FirestoreのTODOコレクション参照を取得
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

  // TODOの詳細データをFirestoreから取得し、リアルタイムで更新をリッスン
  void _fetchTodoDetails() {
    _getTodoCollection().doc(widget.todoDocId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _todoDoc = snapshot;
          final data = snapshot.data() as Map<String, dynamic>? ?? {}; // nullチェックを追加
          _textController.text = data['text'] as String? ?? '';
          _memoController.text = data['memo'] as String? ?? '';
          _selectedDueDate = (data['dueDate'] as Timestamp?)?.toDate();
          _imageUrl = data['imageUrl'] as String?; // 画像URLを取得
        });
      } else {
        // ドキュメントが存在しない場合（削除された場合など）
        Navigator.of(context).pop(); // 前の画面に戻る
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TODOが見つかりませんでした。')),
        );
      }
    }, onError: (error) {
      print('TODO詳細取得エラー: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODO詳細の取得に失敗しました: $error')),
      );
    });
  }

  // TODOを更新する
  Future<void> _updateTodo() async {
    final String newText = _textController.text.trim();
    final String newMemo = _memoController.text.trim();

    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TODO名を入力してください。')),
      );
      return;
    }

    try {
      await _getTodoCollection().doc(widget.todoDocId).update({
        'text': newText,
        'memo': newMemo,
        'dueDate': _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
        // imageUrlは画像アップロード時に更新されるため、ここでは含めない
      });
      setState(() {
        _isEditing = false; // 編集モードを終了
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TODOを更新しました！')),
      );
    } catch (e) {
      print('TODO更新エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODOの更新に失敗しました: $e')),
      );
    }
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

  // 画像を選択してアップロード
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画像をアップロード中...')),
    );

    try {
      final String fileName = '${_userId}/${widget.todoDocId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('todo_images').child(fileName);

      final UploadTask uploadTask = storageRef.putFile(File(image.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestoreに画像URLを保存
      await _getTodoCollection().doc(widget.todoDocId).update({
        'imageUrl': downloadUrl,
      });

      setState(() {
        _imageUrl = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像をアップロードしました！')),
      );
    } catch (e) {
      print('画像アップロードエラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像のアップロードに失敗しました: $e')),
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
              panEnabled: true, // パン操作を有効にする
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
    if (_todoDoc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TODO詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _todoDoc!.data() as Map<String, dynamic>? ?? {};
    final bool isCompleted = data['isCompleted'] as bool? ?? false;
    final String text = data['text'] as String? ?? '無題のTODO';
    final String memo = data['memo'] as String? ?? '';
    final Timestamp? dueDateTimestamp = data['dueDate'] as Timestamp?;
    final String? dueDateText = dueDateTimestamp != null
        ? DateFormat('yyyy/MM/dd HH:mm').format(dueDateTimestamp.toDate())
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO詳細'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true; // 編集モードに入る
                });
              },
              tooltip: '編集',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateTodo, // 保存ボタン
              tooltip: '保存',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false; // 編集モードをキャンセル
                  // 変更を破棄し、元の値に戻す
                  _textController.text = data['text'] as String? ?? '';
                  _memoController.text = data['memo'] as String? ?? '';
                  _selectedDueDate = (data['dueDate'] as Timestamp?)?.toDate();
                });
              },
              tooltip: 'キャンセル',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO名
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'TODO名',
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing, // 編集モードでのみ編集可能
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 期限日
            Row(
              children: [
                Expanded(
                  child: Text(
                    dueDateText != null ? '期限: $dueDateText' : '期限: 未設定',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(context, initialDateTime: _selectedDueDate), // ★修正★
                    tooltip: '期限日を設定',
                  ),
                if (_isEditing && _selectedDueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                    tooltip: '期限日をクリア',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 備考
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '備考',
                border: OutlineInputBorder(),
                alignLabelWithHint: true, // ラベルを上部に揃える
              ),
              enabled: _isEditing, // 編集モードでのみ編集可能
              maxLines: null, // 複数行入力可能
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // 画像添付/変更ボタン
            if (_isEditing)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.image),
                  label: Text(_imageUrl != null ? '画像を変更' : '画像を添付'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // 添付画像表示
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Center(
                child: GestureDetector(
                  onTap: () => _showImageDialog(_imageUrl!), // タップで拡大表示
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        _imageUrl!,
                        width: MediaQuery.of(context).size.width * 0.8, // 画面幅の80%
                        height: 200, // 固定の高さ
                        fit: BoxFit.cover, // 画像がコンテナに収まるように調整
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
              ),
            if (_imageUrl != null && _imageUrl!.isNotEmpty && _isEditing)
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    // 画像削除の確認ダイアログ
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
                        // Firebase Storageから画像を削除
                        await FirebaseStorage.instance.refFromURL(_imageUrl!).delete();
                        // FirestoreからURLを削除
                        await _getTodoCollection().doc(widget.todoDocId).update({'imageUrl': FieldValue.delete()});
                        setState(() {
                          _imageUrl = null;
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
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('画像を削除', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
