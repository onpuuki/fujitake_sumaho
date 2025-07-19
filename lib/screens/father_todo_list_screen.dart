import 'package:flutter/material.dart';

class FatherTodoListScreen extends StatelessWidget {
  const FatherTodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お父さんのTODOリスト'),
      ),
      body: const Center(
        child: Text('お父さんのTODOリストの画面です（準備中）'),
      ),
    );
  }
}
