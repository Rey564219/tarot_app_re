import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'bundle_screen.dart';
import 'reading_screen.dart';

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

  Future<void> _execute(String fortuneTypeKey) async {
    setState(() => _loading = true);
    try {
      final response = await AppSession.instance.api.postJson('/readings/execute', {
        'fortune_type_key': fortuneTypeKey,
      });
      final readingId = response['reading_id'] as String;
      final result = response['result_json'];
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReadingScreen(readingId: readingId, resultJson: result),
        ),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('実行エラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        SnackBar(content: Text('回復に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _executeBundle() async {
    setState(() => _loading = true);
    try {
      final response = await AppSession.instance.api.postJson('/readings/execute-batch', {
        'fortune_type_keys': [
          'week_one',
          'today_deep_love',
          'today_deep_work',
          'today_deep_money',
          'today_deep_trouble',
        ],
      });
      final items = response['items'] as List<dynamic>;
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BundleScreen(items: items),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('一括実行エラー: $e')),
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
      subtitle: '無料 → 課金導線の起点。今日の運勢と深掘りを中心に。',
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
                    '今日の運勢',
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
            title: '今日の運勢 1枚引き',
            subtitle: '無料で今日のテーマを確認。',
            badge: 'FREE',
            onTap: _loading ? () {} : () => _execute('today_free'),
          ),
          FortuneCard(
            title: '今日の運勢 深掘り',
            subtitle: '恋愛・仕事・金運・トラブルを追加で深掘り。',
            badge: subActive ? 'SUB' : 'LOCK',
            onTap: _loading ? () {} : () => _execute('today_deep_love'),
            trailing: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _rewardAd,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('動画広告でライフ回復 +2'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '深掘りメニュー',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _executeBundle,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('サブスク一括で引く'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipButton('恋愛', () => _execute('today_deep_love')),
              _chipButton('仕事', () => _execute('today_deep_work')),
              _chipButton('金運', () => _execute('today_deep_money')),
              _chipButton('トラブル', () => _execute('today_deep_trouble')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: _loading ? null : onTap,
      child: Text(label),
    );
  }
}
