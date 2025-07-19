import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestoreが必要な場合
import 'firebase_options.dart';
import 'package:fujitake_app/screens/top_screen.dart'; // TopScreenへの正しいパス

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // FlutterがFirebaseを使用する準備ができたことを保証

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    // 匿名認証でログイン（userIdを取得するため）
    // すでにログイン済みの場合は既存のユーザーを使用
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously. User ID: ${FirebaseAuth.instance.currentUser?.uid}");
    } else {
      print("Already signed in. User ID: ${FirebaseAuth.instance.currentUser?.uid}");
    }

  } catch (e) {
    // Firebase初期化または認証に失敗した場合のログ出力とエラー表示
    print('Firebase initialization or authentication failed: $e');
    // エラーが発生した場合でもアプリがクラッシュしないように、エラーメッセージを表示する画面を表示
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Firebaseエラー')),
          body: Center(
            child: Text('Firebaseの初期化または認証に失敗しました。\nエラー: $e', textAlign: TextAlign.center,),
          ),
        ),
      ),
    );
    return; // エラー時はここで処理を終了し、アプリの起動を停止
  }

  // Firebaseの初期化と認証が成功した場合のみMyAppを実行
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ふじたけアプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TopScreen(), // アプリのホーム画面としてTopScreenを表示
    );
  }
}