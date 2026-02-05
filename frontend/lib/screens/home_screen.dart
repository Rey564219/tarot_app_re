import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'draw_screen.dart';
import 'batch_draw_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  Map<String, dynamic>? _life;
  Map<String, dynamic>? _billing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _error = null;
    });
    try {
      final life = await AppSession.instance.api.getJson('/life');
      final billing = await AppSession.instance.api.getJson('/billing/status');
      setState(() {
        _life = life;
        _billing = billing;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _openDraw(String fortuneTypeKey, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: fortuneTypeKey,
          title: title,
          showAiInterpretation: true,
        ),
      ),
    );
  }

  void _openDeepBatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BatchDrawScreen(
          title: '今日の運勢 深掘り（サブスク）',
          fortuneTypeKeys: [
            'today_deep_love',
            'today_deep_work',
            'today_deep_money',
            'today_deep_trouble',
          ],
          labels: {
            'today_deep_love': '恋愛',
            'today_deep_work': '仕事',
            'today_deep_money': '金運',
            'today_deep_trouble': 'トラブル',
          },
        ),
      ),
    );
  }

  Future<void> _rewardAd() async {
    setState(() => _loading = true);
    try {
      await AppSession.instance.api.postJson('/ads/reward/complete', {
        'ad_provider': 'demo',
        'placement': 'home_life_recover',
        'reward_amount': 2,
      });
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('広告でエラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lifeText = _life == null
        ? 'Life: --/--'
        : 'Life: ${_life!['current_life']}/${_life!['max_life']}';
    final subActive = _billing?['subscription_active'] == true;

    return AppScaffold(
      title: 'Home',
      subtitle: '今日の運勢とサブスクメニューを選べます。',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadStatus,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1F2E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ライフ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                Text(
                  lifeText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 18),
          FortuneCard(
            title: '無料一枚引き',
            subtitle: '今日の運勢を1枚でみます。',
            badge: 'FREE',
            onTap: _loading ? () {} : () => _openDraw('today_free', '無料一枚引き'),
          ),
          FortuneCard(
            title: '今日の運勢 深掘り（サブスク）',
            subtitle: '恋愛・仕事・金運・トラブルをまとめて表示。',
            badge: subActive ? 'SUB' : 'LOCK',
            onTap: _loading ? () {} : _openDeepBatch,
            trailing: const Icon(Icons.lock_outline),
          ),
          FortuneCard(
            title: '一週間の運勢 深掘り（サブスク）',
            subtitle: '恋愛・仕事・金運・トラブル総合を5枚で読みます。',
            badge: subActive ? 'SUB' : 'LOCK',
            onTap: _loading ? () {} : () => _openDraw('week_one', '一週間の運勢 深掘り'),
            trailing: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _rewardAd,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('広告でライフ回復 +2'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
