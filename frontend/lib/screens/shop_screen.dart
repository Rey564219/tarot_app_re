import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _loading = true;
  String? _error;
  List<_ShopItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AppSession.instance.api.getJson('/shop/items');
      final items = response['items'] as List<dynamic>? ?? [];
      setState(() {
        _items = items
            .whereType<Map<String, dynamic>>()
            .map(_ShopItem.fromJson)
            .toList(growable: false);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startCheckout(_ShopItem item, String method) async {
    try {
      final response = await AppSession.instance.api.postJson('/shop/checkout/start', {
        'item_id': item.id,
        'payment_method': method,
      });
      final checkoutUrl = response['checkout_url']?.toString() ?? '';
      if (checkoutUrl.isEmpty) {
        throw Exception('決済URLが取得できませんでした');
      }

      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null || (!uri.hasScheme)) {
        throw Exception('決済URLが不正です');
      }
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('決済ページを開けませんでした')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('決済の開始に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Shop',
      subtitle: '天然石アクセサリーと性癖トランプの販売です。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text('取得に失敗しました: $_error', style: const TextStyle(color: Colors.red))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._items.map((item) => _ShopCard(
                          item: item,
                          onTapPayPay: () => _startCheckout(item, 'paypay'),
                          onTapStripe: () => _startCheckout(item, 'stripe'),
                        )),
                  ],
                ),
    );
  }
}

class _ShopItem {
  const _ShopItem({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.currency,
  });

  factory _ShopItem.fromJson(Map<String, dynamic> json) {
    return _ShopItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'JPY',
    );
  }

  final String id;
  final String name;
  final int priceCents;
  final String currency;

  String get priceLabel {
    if (currency.toUpperCase() == 'JPY') {
      return '¥${priceCents.toString()}';
    }
    final value = (priceCents / 100).toStringAsFixed(2);
    return '$value ${currency.toUpperCase()}';
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.item,
    required this.onTapPayPay,
    required this.onTapStripe,
  });

  final _ShopItem item;
  final VoidCallback onTapPayPay;
  final VoidCallback onTapStripe;

  @override
  Widget build(BuildContext context) {
    return FortuneCard(
      title: item.name,
      subtitle: item.priceLabel,
      onTap: () {},
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: onTapPayPay,
                child: const Text('PayPay'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onTapStripe,
                child: const Text('クレカ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
