import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'product_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _loading = true;
  List<dynamic> _fortuneTypes = [];
  List<dynamic> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Shop',
      subtitle: '買い切り占い。購入後に結果を実行。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ..._products.map((product) {
            final fortuneType = _fortuneTypes.firstWhere(
              (ft) => ft['id'] == product['fortune_type_id'],
              orElse: () => null,
            );
            return FortuneCard(
              title: fortuneType?['name'] ?? product['name'],
              subtitle: '¥${product['price_cents']} ${product['currency']}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductScreen(productId: product['id']),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
