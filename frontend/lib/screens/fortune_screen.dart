import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'warning_screen.dart';
import 'product_screen.dart';
import 'draw_screen.dart';

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
      final filtered = products.where((p) => p['platform'] == null || p['platform'] == 'android').toList();
      setState(() {
        _fortuneTypes = types;
        _products = filtered;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDraw(String fortuneTypeKey, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: fortuneTypeKey,
          title: title,
          showAiInterpretation: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    return AppScaffold(
      title: 'Fortune',
      subtitle: '一日の運勢や有料鑑定を選べます。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMaster),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FortuneCard(
            title: '今日のワンオラクル',
            subtitle: 'ライフカードを2枚引きます。',
            badge: 'LIFE',
            onTap: () => _openDraw('no_desc_draw', '今日のワンオラクル'),
          ),
          const SizedBox(height: 8),
          Text('有料鑑定', style: Theme.of(context).textTheme.titleMedium),
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
