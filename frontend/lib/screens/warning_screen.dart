import 'package:flutter/material.dart';

import '../app_session.dart';
import 'product_screen.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key, required this.fortuneTypeKey, this.onAccepted});

  final String fortuneTypeKey;
  final VoidCallback? onAccepted;

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await AppSession.instance.api.postJson('/warnings/accept', {
        'fortune_type_key': widget.fortuneTypeKey,
      });
      if (widget.onAccepted != null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onAccepted?.call();
      } else {
        await _navigateToProduct();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('警告の承認に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToProduct() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProductScreen(fortuneTypeKey: widget.fortuneTypeKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('警告')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '犯罪・不正・トライアングル占い',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'この占いは毎回警告が表示されます。実行を続ける場合は注意事項に同意してください。',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('戻る'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _accept,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('同意して進む'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
