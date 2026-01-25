import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'reading_screen.dart';
import 'warning_screen.dart';
import 'product_screen.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  bool _loading = true;
  List<dynamic> _fortuneTypes = [];
  List<dynamic> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaster();
  }

  Future<void> _loadMaster() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await AppSession.instance.api.getList('/master/fortune-types');
      final products = await AppSession.instance.api.getList('/master/products');
      setState(() {
        _fortuneTypes = types;
        _products = products;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _executeLife() async {
    try {
      final response = await AppSession.instance.api.postJson('/readings/execute', {
        'fortune_type_key': 'no_desc_draw',
      });
      final readingId = response['reading_id'] as String;
      final result = response['result_json'];
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReadingScreen(readingId: readingId, resultJson: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ライフ不足またはエラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    return AppScaffold(
      title: 'Fortune',
      subtitle: '説明なし引きと買い切り占いの入口。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMaster),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FortuneCard(
            title: '説明なしカード引き',
            subtitle: 'ライフ消費で2枚引き。',
            badge: 'LIFE',
            onTap: _executeLife,
          ),
          const SizedBox(height: 8),
          Text('買い切り占い', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ...products.map((product) {
            final fortuneType = _fortuneTypes.firstWhere(
              (ft) => ft['id'] == product['fortune_type_id'],
              orElse: () => null,
            );
            final fortuneKey = fortuneType?['key'] ?? 'unknown';
            final requiresWarning = fortuneType?['requires_warning'] == true;
            return FortuneCard(
              title: fortuneType?['name'] ?? product['name'],
              subtitle: '¥${product['price_cents']} ${product['currency']}',
              badge: requiresWarning ? 'WARNING' : 'ONE-TIME',
              onTap: () {
                if (requiresWarning) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WarningScreen(
                        fortuneTypeKey: fortuneKey,
                        onAccepted: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductScreen(productId: product['id']),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductScreen(productId: product['id']),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
