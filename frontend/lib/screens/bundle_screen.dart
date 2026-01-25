import 'package:flutter/material.dart';

import '../app_session.dart';
import 'reading_screen.dart';

class BundleScreen extends StatelessWidget {
  const BundleScreen({super.key, required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サブスク一括結果')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(item['fortune_type_key'] ?? ''),
              subtitle: const Text('結果ページを表示'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReadingScreen(
                      readingId: item['reading_id'],
                      resultJson: item['result_json'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
