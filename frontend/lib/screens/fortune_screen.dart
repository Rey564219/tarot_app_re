import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import '../widgets/life_banner.dart';
import 'warning_screen.dart';
import 'product_screen.dart';
import 'draw_screen.dart';
import 'compatibility_screen.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  bool _loading = true;
  List<dynamic> _fortuneTypes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaster();
  }

  Future<void> _loadMaster() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await AppSession.instance.api.getList('/master/fortune-types');
      setState(() {
        _fortuneTypes = types;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDraw(
    String fortuneTypeKey,
    String title, {
    bool useDetailedQuestionForm = false,
    bool showAiInterpretation = true,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: fortuneTypeKey,
          title: title,
          showAiInterpretation: showAiInterpretation,
          useDetailedQuestionForm: useDetailedQuestionForm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> _mergeTodayDeepFortunes() {
      final merged = <Map<String, dynamic>>[];
      Map<String, dynamic>? firstDeep;
      int? deepInsertIndex;

      for (final fortune in _fortuneTypes) {
        if (fortune is! Map<String, dynamic>) continue;
        final key = fortune['key']?.toString() ?? '';
        if (key.startsWith('today_deep_')) {
          deepInsertIndex ??= merged.length;
          firstDeep ??= Map<String, dynamic>.from(fortune);
          continue;
        }
        merged.add(fortune);
      }

      if (firstDeep != null) {
        final aggregated = Map<String, dynamic>.from(firstDeep!);
        aggregated['key'] = 'today_deep_love';
        aggregated['name'] = '今日の運勢 深掘り';
        aggregated['description'] = '総合・恋愛・仕事・金運・トラブルをまとめて読みます。';
        merged.insert(deepInsertIndex ?? merged.length, aggregated);
      }

      return merged;
    }

    final mergedFortunes = _mergeTodayDeepFortunes();

    String _genreLabel(String? accessType) {
      final normalized = (accessType ?? '').toLowerCase();
      if (normalized == 'free' || normalized == 'life') return 'LIFE';
      if (normalized == 'subscription' || normalized == 'sub') return 'SUB';
      if (normalized == 'one_time' || normalized == 'purchase' || normalized == 'paid') return 'BUY';
      return normalized.toUpperCase();
    }

    List<Map<String, dynamic>> _filtered(String bucket) {
      return mergedFortunes
          .where((fortuneType) {
            final accessType = fortuneType['access_type_default']?.toString().toLowerCase();
            final key = fortuneType['key']?.toString() ?? '';
            if (key == 'compatibility' || key == 'no_desc_draw') return false;
            switch (bucket) {
              case 'life':
                return accessType == 'life' || accessType == 'free';
              case 'sub':
                return accessType == 'subscription' || accessType == 'sub';
              case 'paid':
                return accessType == 'purchase' || accessType == 'paid' || accessType == 'one_time';
              default:
                return accessType != 'free' &&
                    accessType != 'subscription' &&
                    accessType != 'sub' &&
                    accessType != 'purchase' &&
                    accessType != 'paid' &&
                    accessType != 'one_time';
            }
          })
          .toList();
    }

    List<Widget> _buildSection(String title, List<Map<String, dynamic>> fortuneTypes) {
      if (fortuneTypes.isEmpty) return const <Widget>[];
      return [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...fortuneTypes.map((fortuneType) {
          final fortuneKey = fortuneType['key']?.toString() ?? '';
          final requiresWarning = fortuneType['requires_warning'] == true;
          final accessType = fortuneType['access_type_default']?.toString();
          final isOneTime = accessType?.toLowerCase() == 'one_time';
          final description = fortuneType['description']?.toString().trim();
          final subtitle =
              (description != null && description.isNotEmpty) ? description : '占いを実行します。';
          final genre = _genreLabel(accessType);
          final showAi = fortuneKey != 'no_desc_draw';
          return FortuneCard(
            title: fortuneType['name'] ?? fortuneKey,
            subtitle: subtitle,
            genre: genre,
            badge: requiresWarning ? 'WARNING' : null,
            onTap: () {
              void openFortune() {
                if (isOneTime) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductScreen(fortuneTypeKey: fortuneKey),
                    ),
                  );
                } else {
                  _openDraw(
                    fortuneKey,
                    fortuneType['name'] ?? fortuneKey,
                    useDetailedQuestionForm: isOneTime,
                    showAiInterpretation: showAi,
                  );
                }
              }

              if (requiresWarning) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WarningScreen(
                      fortuneTypeKey: fortuneKey,
                      onAccepted: openFortune,
                    ),
                  ),
                );
              } else {
                openFortune();
              }
            },
          );
        }),
        const SizedBox(height: 16),
      ];
    }

    final sections = [
      {'title': 'ライフ占い', 'items': _filtered('life')},
      {'title': '相性占い', 'items': const <Map<String, dynamic>>[]},
      {'title': 'サブスク占い', 'items': _filtered('sub')},
      {'title': '買い切り占い', 'items': _filtered('paid')},
      {'title': 'その他の占い', 'items': _filtered('other')},
    ];

    return AppScaffold(
      title: 'Fortune',
      subtitle: '',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMaster),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const LifeBanner(),
          for (final section in sections)
            if (section['title'] == '相性占い')
              ..._buildCompatibilitySection(context)
            else
              ..._buildSection(
                section['title']! as String,
                (section['items']! as List<Map<String, dynamic>>),
              ),
        ],
      ),
    );
  }

  List<Widget> _buildCompatibilitySection(BuildContext context) {
    return [
      Text('相性占い', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      FortuneCard(
        title: '相性占い（恋愛）',
        subtitle: '恋愛の相性をみます。',
        badge: 'LIFE',
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
        badge: 'LIFE',
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
    ];
  }
}
