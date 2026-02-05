import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import 'question_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final title = _fortuneType?['name'] ?? _product?['name'] ?? 'Product';
    final description = _fortuneType?['description'];
    return AppScaffold(
      title: '商品詳細',
      subtitle: '内容を確認して、カードを引いてください。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProduct),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(_product),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (description != null && description.toString().trim().isNotEmpty) ...[
                      Text(description.toString(), style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFAF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ワンタイム鑑定です。カードを引いた後に結果が表示されます。',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _fortuneType == null
                            ? null
                            : () {
                                final accessType = _fortuneType?['access_type_default']?.toString();
                                final showAiInterpretation = true;
                                final allowManualAi = accessType != 'one_time';
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => QuestionScreen(
                                      title: title,
                                      fortuneTypeKey: _fortuneType!['key'],
                                      showAiInterpretation: showAiInterpretation,
                                      allowManualAi: allowManualAi,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.style),
                        label: const Text('カードを引く'),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatPrice(Map<String, dynamic>? product) {
    if (product == null) return '';
    final priceCents = product['price_cents'];
    final currencyRaw = product['currency']?.toString().toUpperCase() ?? '';
    if (priceCents is num) {
      if (currencyRaw == 'JPY') {
        return '価格: \u00a5${priceCents.toInt()}';
      }
      final value = (priceCents / 100).toStringAsFixed(2);
      return '価格: $value $currencyRaw';
    }
    return '価格: $priceCents $currencyRaw';
  }
}
