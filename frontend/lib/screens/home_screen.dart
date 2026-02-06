import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'draw_screen.dart';
import 'compatibility_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDraw(BuildContext context, String fortuneTypeKey, String title,
      {bool showAiInterpretation = true}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: fortuneTypeKey,
          title: title,
          showAiInterpretation: showAiInterpretation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      subtitle: '占いを選んで進めてください。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('無料一枚引き', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FortuneCard(
            title: '無料一枚引き',
            subtitle: '今日の運勢を1枚でみます。',
            badge: 'FREE',
            onTap: () => _openDraw(context, 'today_free', '無料一枚引き'),
          ),
          FortuneCard(
            title: 'ツーオラクル（説明なし）',
            subtitle: '2枚のカードだけを表示します。',
            badge: 'FREE',
            onTap: () => _openDraw(context, 'no_desc_draw', 'ツーオラクル（説明なし）', showAiInterpretation: false),
          ),
          const SizedBox(height: 16),
          Text('相性占い', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FortuneCard(
            title: '相性占い（恋愛）',
            subtitle: '恋愛の相性をみます。',
            badge: 'FREE',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CompatibilityScreen(
                    title: '相性占い（恋愛）',
                    subtitle: '恋愛の相性を3枚で読みます。',
                    category: 'love',
                  ),
                ),
              );
            },
          ),
          FortuneCard(
            title: '相性占い（人間関係）',
            subtitle: '仕事・友人などの相性をみます。',
            badge: 'FREE',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CompatibilityScreen(
                    title: '相性占い（人間関係）',
                    subtitle: '人間関係の相性を3枚で読みます。',
                    category: 'relationship',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('サブスク占い', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FortuneCard(
            title: '今日の運勢 深掘り',
            subtitle: '総合・恋愛・仕事・金運・トラブルをまとめて読みます。',
            badge: 'SUB',
            onTap: () => _openDraw(context, 'today_deep_love', '今日の運勢 深掘り'),
          ),
          FortuneCard(
            title: '一週間の運勢',
            subtitle: '総合・恋愛・仕事・金運・トラブルをまとめて読みます。',
            badge: 'SUB',
            onTap: () => _openDraw(context, 'week_one', '一週間の運勢'),
          ),
          const SizedBox(height: 16),
          Text('Shop', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FortuneCard(
            title: '占い（買い切り）・物販',
            subtitle: '購入一覧へ。',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
