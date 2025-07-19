import 'package:flutter/material.dart';

// 各機能の画面ファイルをインポートします。
import 'package:fujitake_app/screens/father_screen.dart';
import 'package:fujitake_app/screens/mother_screen.dart';
import 'package:fujitake_app/screens/shared_screen.dart';
// プロンプトコピーとデバッグ機能はFatherScreenから遷移するため、ここでは削除
// import 'package:fujitake_app/screens/prompt_copy_screen.dart';
// import 'package:fujitake_app/screens/debug_screen.dart';


class TopScreen extends StatelessWidget {
  const TopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ふじたけアプリ - トップ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ふじたけアプリへようこそ！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // お父さん機能ボタン
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FatherScreen()),
                );
              },
              child: const Text('お父さん機能'),
            ),
            const SizedBox(height: 10),
            // お母さん機能ボタン
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MotherScreen()),
                );
              },
              child: const Text('お母さん機能'),
            ),
            const SizedBox(height: 10),
            // 共通機能ボタン
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SharedScreen()),
                );
              },
              child: const Text('共通機能'),
            ),
            // プロンプトコピーとデバッグ機能のボタンは削除
            // const SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const PromptCopyScreen()),
            //     );
            //   },
            //   child: const Text('プロンプトコピー'),
            // ),
            // const SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const DebugScreen()),
            //     );
            //   },
            //   child: const Text('デバッグ機能'),
            // ),
          ],
        ),
      ),
    );
  }
}
