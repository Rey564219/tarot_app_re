import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<_ShopItem> _items = const [
    _ShopItem(
      name: '恋愛運：アメジスト、ローズクォーツ',
      price: '¥7,800',
      imageLabel: '恋愛運',
      url: '',
    ),
    _ShopItem(
      name: '仕事運：タイガーアイ、アンバー',
      price: '¥7,800',
      imageLabel: '仕事運',
      url: '',
    ),
    _ShopItem(
      name: '健康運：トルマリン、ブラックルチル、スモーキークォーツ',
      price: '¥7,800',
      imageLabel: '健康運',
      url: '',
    ),
    _ShopItem(
      name: '金運：ヘマタイト、ルチルクォーツ',
      price: '¥10,800',
      imageLabel: '金運',
      url: '',
    ),
    _ShopItem(
      name: 'お守り：ラピスラズリ、クリスタル',
      price: '¥10,800',
      imageLabel: 'お守り',
      url: '',
    ),
    _ShopItem(
      name: '職人との相談で決めるメニュー',
      price: '¥15,800',
      imageLabel: '相談',
      url: '',
    ),
    _ShopItem(
      name: '性癖トランプ',
      price: '¥3,800',
      imageLabel: '性癖トランプ',
      url: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Shop',
      subtitle: '天然石アクセサリーと性癖トランプの販売です。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._items.map((item) => _ShopCard(item: item)),
        ],
      ),
    );
  }
}

class _ShopItem {
  const _ShopItem({
    required this.name,
    required this.price,
    required this.imageLabel,
    required this.url,
  });

  final String name;
  final String price;
  final String imageLabel;
  final String url;
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.item,
  });

  final _ShopItem item;

  @override
  Widget build(BuildContext context) {
    final hasUrl = item.url.trim().isNotEmpty;
    return FortuneCard(
      title: item.name,
      subtitle: item.price,
      onTap: () {},
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: hasUrl
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('決済URL: ${item.url}')),
                      );
                    }
                  : null,
              child: const Text('決済ページへ'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
