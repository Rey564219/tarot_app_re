import 'package:flutter/material.dart';

import '../app_session.dart';
import 'reading_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _loading = true;
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _fortuneType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await AppSession.instance.api.getList('/master/products');
      final product = products.firstWhere((p) => p['id'] == widget.productId);
      final types = await AppSession.instance.api.getList('/master/fortune-types');
      final fortuneType = types.firstWhere((ft) => ft['id'] == product['fortune_type_id']);
      setState(() {
        _product = product;
        _fortuneType = fortuneType;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _execute() async {
    try {
      final response = await AppSession.instance.api.postJson('/readings/execute', {
        'fortune_type_key': _fortuneType!['key'],
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
        SnackBar(content: Text('実行エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品詳細')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fortuneType?['name'] ?? _product?['name'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('価格: ¥${_product?['price_cents']} ${_product?['currency']}'),
                      const SizedBox(height: 8),
                      Text('プラットフォーム: ${_product?['platform']}'),
                      const SizedBox(height: 16),
                      const Text(
                        '購入はストア連携が必要です。ここではバックエンド接続の確認用に「実行」できます。',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _fortuneType == null ? null : _execute,
                          child: const Text('実行（テスト用）'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
