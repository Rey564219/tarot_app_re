import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';
import 'reading_screen.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({
    super.key,
    this.title = '相性占い',
    this.subtitle = 'お二人の相性を3枚で読みます。',
    this.category,
  });

  final String title;
  final String subtitle;
  final String? category;

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await AppSession.instance.api.postJson('/readings/execute', {
        'fortune_type_key': 'compatibility',
        'input_json': {
          'name': _nameController.text,
          'partner': _partnerController.text,
          'note': _noteController.text,
          if (widget.category != null) 'category': widget.category,
        },
      });
      final readingId = response['reading_id'] as String;
      final result = response['result_json'];
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReadingScreen(readingId: readingId, resultJson: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('相性占いエラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'あなたの名前'),
              validator: (value) => value == null || value.isEmpty ? '入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partnerController,
              decoration: const InputDecoration(labelText: '相手の名前'),
              validator: (value) => value == null || value.isEmpty ? '入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '補足（任意）'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('相性をみる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
