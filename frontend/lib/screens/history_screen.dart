import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import 'reading_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<dynamic> _readings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await AppSession.instance.api.getJson('/readings?limit=20');
      if (!mounted) return;
      setState(() {
        _readings = (response['items'] as List<dynamic>? ?? []);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'History',
      subtitle: '過去の占い履歴を確認できます。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReadings),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (!_loading && _error == null && _readings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '履歴はまだありません。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ..._readings.map((reading) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFAF6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                title: Text('Reading ${reading['id']}'),
                subtitle: Text(reading['created_at'].toString()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(readingId: reading['id']),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
