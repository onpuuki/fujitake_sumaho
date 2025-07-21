import 'package:flutter/material.dart';
import 'package:fujitake_app/screens/prompt_copy_screen.dart';
import 'package:fujitake_app/screens/debug_screen.dart';
import 'package:fujitake_app/screens/father_todo_list_screen.dart';
import 'package:fujitake_app/screens/favorite_websites_list_screen.dart'; // ★追加★ お気に入りサイト画面をインポート

class FatherScreen extends StatelessWidget {
  const FatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お父さん機能'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // お父さんのTODOリストボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FatherTodoListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('お父さんのTODOリスト'),
                ),
              ),
            ),
            // お気に入りサイトボタン ★追加★
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoriteWebsitesListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('お気に入りサイト'),
                ),
              ),
            ),
            // プロンプトコピーボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PromptCopyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('プロンプトコピー'),
                ),
              ),
            ),
            // デバッグ機能ボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                width: 280,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DebugScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('デバッグ機能'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
