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
        const SnackBar(content: Text('??????????')),
      );
      _openQuestion();
    } catch (e) {
      if (!mounted) return;
      setState(() => _purchaseError = '?????????: $e');
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
      title: '????',
      subtitle: '????????????????????????',
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
                        '?????????????????????????',
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
                        label: Text(_purchasing ? '???...' : '??????'),
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
        return '??: \u00a5${priceCents.toInt()}';
      }
      final value = (priceCents / 100).toStringAsFixed(2);
      return '??: $value $currencyRaw';
    }
    return '??: $priceCents $currencyRaw';
  }
}
