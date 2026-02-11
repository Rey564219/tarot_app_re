import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import 'question_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.fortuneTypeKey});

  final String fortuneTypeKey;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _loading = true;
  bool _purchasing = false;
  Map<String, dynamic>? _product;
  Map<String, dynamic>? _fortuneType;
  String? _error;
  String? _purchaseError;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
      _purchaseError = null;
    });
    try {
      final types = await AppSession.instance.api.getList('/master/fortune-types');
      final products = await AppSession.instance.api.getList('/master/products');
      final fortuneType = types.firstWhere(
        (ft) => ft['key'] == widget.fortuneTypeKey,
        orElse: () => throw Exception('Fortune type not found'),
      ) as Map<String, dynamic>;
      final product = products.firstWhere(
        (p) => p['fortune_type_id'] == fortuneType['id'],
        orElse: () => throw Exception('Product not found'),
      ) as Map<String, dynamic>;
      setState(() {
        _fortuneType = fortuneType;
        _product = product;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _purchaseAndDraw() async {
    if (_fortuneType == null || _purchasing) return;
    setState(() {
      _purchasing = true;
      _purchaseError = null;
    });
    try {
      await AppSession.instance.api.postJson('/billing/mock/purchase', {
        'fortune_type_key': _fortuneType!['key'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u6c7a\u6e08\u304c\u5b8c\u4e86\u3057\u307e\u3057\u305f\u3002')),
      );
      _openQuestion();
    } catch (e) {
      if (!mounted) return;
      setState(() => _purchaseError = '\u6c7a\u6e08\u306b\u5931\u6557\u3057\u307e\u3057\u305f: $e');
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
      }
    }
  }

  void _openQuestion() {
    if (_fortuneType == null) return;
    final title = _fortuneType?['name'] ?? _product?['name'] ?? 'Product';
    final accessType = _fortuneType?['access_type_default']?.toString();
    final fortuneKey = _fortuneType?['key']?.toString() ?? '';
    final showAiInterpretation = fortuneKey != 'no_desc_draw';
    final allowManualAi = accessType != 'one_time';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          title: title,
          fortuneTypeKey: _fortuneType!['key'],
          showAiInterpretation: showAiInterpretation,
          allowManualAi: allowManualAi,
          useDetailedQuestionForm: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _fortuneType?['name'] ?? _product?['name'] ?? 'Product';
    final description = _fortuneType?['description'];
    return AppScaffold(
      title: '\u5546\u54c1\u8a73\u7d30',
      subtitle: '\u5185\u5bb9\u3092\u78ba\u8a8d\u3057\u3066\u3001\u6c7a\u6e08\u5f8c\u306b\u30ab\u30fc\u30c9\u3092\u5f15\u3044\u3066\u304f\u3060\u3055\u3044\u3002',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProduct),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text('\u53d6\u5f97\u306b\u5931\u6557\u3057\u307e\u3057\u305f: \$_error', style: const TextStyle(color: Colors.red))
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
                        '\u30ef\u30f3\u30bf\u30a4\u30e0\u9271\u5bdf\u3067\u3059\u3002\u6c7a\u6e08\u5b8c\u4e86\u5f8c\u306b\u30ab\u30fc\u30c9\u3092\u5f15\u3051\u307e\u3059\u3002',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_purchaseError != null) ...[
                      Text(_purchaseError!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_fortuneType == null || _purchasing) ? null : _purchaseAndDraw,
                        icon: _purchasing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.payment),
                        label: Text(_purchasing ? '\u6c7a\u6e08\u4e2d...' : '\u6c7a\u6e08\u3057\u3066\u5360\u3046'),
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
        return '\u4fa1\u683c: \u00a5${priceCents.toInt()}';
      }
      final value = (priceCents / 100).toStringAsFixed(2);
      return '\u4fa1\u683c: $value $currencyRaw';
    }
    return '\u4fa1\u683c: $priceCents $currencyRaw';
  }
}
