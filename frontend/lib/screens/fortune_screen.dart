import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/fortune_card.dart';
import 'warning_screen.dart';
import 'draw_screen.dart';

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

  void _openDraw(String fortuneTypeKey, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: fortuneTypeKey,
          title: title,
          showAiInterpretation: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Fortune',
      subtitle: 'DBに登録された全占いを一覧表示します。',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMaster),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          ..._fortuneTypes.map((fortuneType) {
            final fortuneKey = fortuneType['key']?.toString() ?? '';
            final requiresWarning = fortuneType['requires_warning'] == true;
            final accessType = fortuneType['access_type_default']?.toString();
            final description = fortuneType['description']?.toString();
            final subtitle = (description != null && description.trim().isNotEmpty)
                ? description
                : (accessType == null || accessType.isEmpty ? '占いを実行します。' : accessType);
            return FortuneCard(
              title: fortuneType['name'] ?? fortuneKey,
              subtitle: subtitle,
              badge: requiresWarning ? 'WARNING' : null,
              onTap: () {
                if (requiresWarning) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WarningScreen(
                        fortuneTypeKey: fortuneKey,
                        onAccepted: () => _openDraw(fortuneKey, fortuneType['name'] ?? fortuneKey),
                      ),
                    ),
                  );
                } else {
                  _openDraw(fortuneKey, fortuneType['name'] ?? fortuneKey);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
