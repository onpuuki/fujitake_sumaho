    import 'package:flutter/material.dart';

    class DebugScreen extends StatelessWidget {
      const DebugScreen({super.key});

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('デバッグ機能'),
          ),
          body: const Center(
            child: Text('デバッグ機能の画面です（準備中）'),
          ),
        );
      }
    }