import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import 'draw_screen.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    super.key,
    required this.title,
    required this.fortuneTypeKey,
    this.showAiInterpretation = true,
    this.allowManualAi = true,
  });

  final String title;
  final String fortuneTypeKey;
  final bool showAiInterpretation;
  final bool allowManualAi;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final _questionController = TextEditingController();
  final _contextController = TextEditingController();
  String _unit = 'month';

  @override
  void dispose() {
    _questionController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _goDraw() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrawScreen(
          fortuneTypeKey: widget.fortuneTypeKey,
          title: widget.title,
          initialQuestion: _questionController.text.trim(),
          initialContext: _contextController.text.trim(),
          initialUnit: widget.fortuneTypeKey == 'flower_timing' ? _unit : null,
          showAiInterpretation: widget.showAiInterpretation,
          allowManualAi: widget.allowManualAi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '質問事項',
      subtitle: 'カードを引く前に、気になることがあれば書いてください。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFAF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.fortuneTypeKey == 'flower_timing') ...[
                  Text('単位', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('1日')),
                      DropdownMenuItem(value: 'week', child: Text('1週間')),
                      DropdownMenuItem(value: 'month', child: Text('1か月')),
                      DropdownMenuItem(value: 'year', child: Text('1年')),
                    ],
                    onChanged: (value) => setState(() => _unit = value ?? 'month'),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('質問（任意）', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(hintText: '例：今の仕事を続けるべき？'),
                ),
                const SizedBox(height: 16),
                Text('補足（任意）', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _contextController,
                  decoration: const InputDecoration(hintText: '例：ここ1年迷っています'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goDraw,
              icon: const Icon(Icons.style),
              label: const Text('カードを引くへ'),
            ),
          ),
        ],
      ),
    );
  }
}
