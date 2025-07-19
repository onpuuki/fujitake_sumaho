import 'package:flutter/material.dart';
import 'package:fujitake_app/screens/prompt_copy_screen.dart'; // プロンプトコピー画面をインポート
import 'package:fujitake_app/screens/debug_screen.dart';       // デバッグ画面をインポート
import 'package:fujitake_app/screens/father_todo_list_screen.dart'; // お父さんのTODOリスト画面をインポート (追加)


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
          children: [
            const Text(
              'お父さん機能の画面です',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // お父さんのTODOリストへのボタン
            ElevatedButton(
              onPressed: () {
                // お父さんのTODOリスト画面へ遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FatherTodoListScreen()),
                );
              },
              child: const Text('お父さんのTODOリスト'),
            ),
            const SizedBox(height: 10),
            // プロンプトコピー機能へのボタンを追加
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromptCopyScreen()),
                );
              },
              child: const Text('プロンプトコピー'),
            ),
            const SizedBox(height: 10),
            // デバッグ機能へのボタンを追加
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
              child: const Text('デバッグ機能'),
            ),
            // その他の「お父さん機能」のボタンをここに追加
          ],
        ),
      ),
    );
  }
}
