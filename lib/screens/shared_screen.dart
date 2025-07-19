    import 'package:flutter/material.dart';

    class SharedScreen extends StatelessWidget {
      const SharedScreen({super.key});

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('共通機能'),
          ),
          body: const Center(
            child: Text('共通機能の画面です（準備中）'),
          ),
        );
      }
    }
    