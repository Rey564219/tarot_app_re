import 'package:flutter/material.dart';

import '../app_session.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.readingId, this.resultJson});

  final String readingId;
  final dynamic resultJson;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  bool _loading = false;
  dynamic _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _result = widget.resultJson;
    if (_result == null) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await AppSession.instance.api.getJson('/readings/${widget.readingId}');
      setState(() => _result = response['result_json']);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('占い結果')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : _result == null
                    ? const Text('結果がありません')
                    : _buildResultView(_result),
      ),
    );
  }

  Widget _buildResultView(dynamic result) {
    if (result is! Map) {
      return ListView(
        children: [
          Text('結果', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(AppSession.prettyJson(result)),
        ],
      );
    }

    final title = result['type']?.toString() ?? 'reading';
    final slots = result['slots'] as List<dynamic>? ?? [];
    final baseCard = result['base_card'];
    final extraCards = result['extra_cards'] as List<dynamic>?;

    return ListView(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (baseCard != null)
          Card(
            child: ListTile(
              title: Text(baseCard['name'] ?? ''),
              subtitle: Text(_formatCard(baseCard)),
            ),
          ),
        ...slots.map((slot) {
          final card = slot['card'];
          return Card(
            child: ListTile(
              title: Text('${slot['position']}'),
              subtitle: Text('${card['name']} • ${_formatCard(card)}'),
            ),
          );
        }).toList(),
        if (extraCards != null && extraCards.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('追加カード', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...extraCards.map((card) {
            return Card(
              child: ListTile(
                title: Text(card['name']),
                subtitle: Text(_formatCard(card)),
              ),
            );
          }).toList(),
        ],
        const SizedBox(height: 16),
        _aiPlaceholder(),
        const SizedBox(height: 16),
        Text('Raw JSON', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(AppSession.prettyJson(result)),
      ],
    );
  }

  String _formatCard(dynamic card) {
    if (card is! Map) return '';
    final suit = card['suit'];
    final rank = card['rank'];
    final arcana = card['arcana'] ?? '';
    final upright = card['upright'];
    final position = upright == null ? '正逆なし' : (upright == true ? '正位置' : '逆位置');
    final detail = suit != null ? '$rank of $suit' : arcana;
    return '$detail / $position';
  }

  Widget _aiPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('AI解釈（後で生成）', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('カード名・簡易意味・配置（過去/現在/未来など）を入力として生成予定。'),
        ],
      ),
    );
  }
}
