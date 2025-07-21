import 'package:flutter/material.dart';
import 'package:fujitake_app/screens/father_screen.dart';
import 'package:fujitake_app/screens/mother_screen.dart';
import 'package:fujitake_app/screens/shared_screen.dart';

class TopScreen extends StatelessWidget {
  const TopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ふじたけアプリ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // お父さん機能ボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox( // ボタンのサイズを制御するためにSizedBoxでラップ
                width: 250, // 幅を大きくする
                height: 70, // 高さを大きくする
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FatherScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角を丸くする
                    ),
                    textStyle: const TextStyle(fontSize: 24), // テキストサイズを大きくする
                  ),
                  child: const Text('お父さん機能'),
                ),
              ),
            ),
            // お母さん機能ボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox( // ボタンのサイズを制御するためにSizedBoxでラップ
                width: 250, // 幅を大きくする
                height: 70, // 高さを大きくする
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MotherScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角を丸くする
                    ),
                    textStyle: const TextStyle(fontSize: 24), // テキストサイズを大きくする
                  ),
                  child: const Text('お母さん機能'),
                ),
              ),
            ),
            // 共通機能ボタン
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox( // ボタンのサイズを制御するためにSizedBoxでラップ
                width: 250, // 幅を大きくする
                height: 70, // 高さを大きくする
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SharedScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // 角を丸くする
                    ),
                    textStyle: const TextStyle(fontSize: 24), // テキストサイズを大きくする
                  ),
                  child: const Text('共通機能'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
