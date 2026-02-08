import 'package:flutter/material.dart';

import '../ads/ad_manager.dart';
import '../app_session.dart';
import '../life_state.dart';

TextStyle _jpTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFamilyFallback: const ['Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', 'sans-serif'],
      ) ??
      const TextStyle(fontWeight: FontWeight.w600, fontFamilyFallback: ['sans-serif']);
}

TextStyle _jpBodyStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamilyFallback: const ['Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', 'sans-serif'],
      ) ??
      const TextStyle(fontFamilyFallback: ['sans-serif']);
}

class LifeBanner extends StatefulWidget {
  const LifeBanner({super.key});

  @override
  State<LifeBanner> createState() => _LifeBannerState();
}

class _LifeBannerState extends State<LifeBanner> {
  bool _loading = false;
  bool _watchingAd = false;
  String? _error;

  LifeState get _lifeState => LifeState.instance;

  @override
  void initState() {
    super.initState();
    _loadLife();
    AdManager.instance.preloadLifeRewardAd();
  }

  Future<void> _loadLife() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _lifeState.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _watchAd() async {
    setState(() {
      _watchingAd = true;
      _error = null;
    });
    try {
      var rewarded = true;
      if (AdManager.instance.isSupported) {
        rewarded = await AdManager.instance.showLifeRewardAd();
      }
      if (!rewarded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('広告の視聴が完了しませんでした。')),
        );
        return;
      }
      await AppSession.instance.api.postJson('/life/ads/reward/complete', {
        'ad_provider': AdManager.instance.isSupported ? 'admob' : 'debug-web',
        'placement': 'life_banner',
        'reward_amount': 2,
      });
      await _lifeState.refresh();
      if (!mounted) return;
      final message = AdManager.instance.isSupported
          ? '広告視聴でライフを2回復しました。'
          : 'テスト環境のためライフを即時回復しました。';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _watchingAd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = _jpTitleStyle(context);
    final bodyStyle = _jpBodyStyle(context);
    return DefaultTextStyle.merge(
      style: bodyStyle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEBE3D9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('ライフ残量', style: titleStyle),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _loadLife,
                ),
              ],
            ),
            if (_error != null) ...[
              Text('取得に失敗しました: ' + _error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ValueListenableBuilder<LifeInfo?>(
              valueListenable: _lifeState.life,
              builder: (context, life, _) {
                if (_loading && life == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 4),
                  );
                }
                if (life == null) {
                  return const Text('ライフ情報がまだありません。しばらくしてから更新してください。');
                }
                return _LifeDetails(
                  life: life,
                  loading: _loading,
                  watchingAd: _watchingAd,
                  onWatchAd: _watchAd,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeDetails extends StatelessWidget {
  const _LifeDetails({
    required this.life,
    required this.loading,
    required this.watchingAd,
    required this.onWatchAd,
  });

  final LifeInfo life;
  final bool loading;
  final bool watchingAd;
  final VoidCallback onWatchAd;

  @override
  Widget build(BuildContext context) {
    final current = life.current;
    final max = life.max;
    final isFull = life.isFull;
    final adSupported = AdManager.instance.isSupported;
    final bodyStyle = _jpBodyStyle(context);

    String buttonLabel() {
      if (watchingAd) return '処理中...';
      if (isFull) return 'ライフは満タンです';
      if (!adSupported) return 'ライフを2回復（テスト）';
      return '広告視聴でライフを2回復';
    }

    final description = isFull
        ? 'ライフは最大です。'
        : adSupported
            ? 'ライフが不足したら広告視聴で2ポイント回復できます。'
            : 'ブラウザなどのテスト環境ではボタンを押すと即時に回復します。';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '現在: ' + '$current / $max',
          style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: max > 0 ? current / max : null,
            minHeight: 10,
            backgroundColor: Colors.white.withOpacity(0.4),
            valueColor: AlwaysStoppedAnimation<Color>(
              isFull ? const Color(0xFF3C6C4D) : const Color(0xFFD99058),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(description, style: bodyStyle),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (watchingAd || loading || isFull) ? null : onWatchAd,
            icon: watchingAd
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(adSupported ? Icons.play_circle_outline : Icons.bolt),
            label: Text(buttonLabel(), style: bodyStyle),
          ),
        ),
      ],
    );
  }
}
