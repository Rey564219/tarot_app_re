import 'package:flutter/material.dart';

import '../app_session.dart';
import '../widgets/app_scaffold.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _loading = true;
  Map<String, dynamic>? _billing;
  List<dynamic> _affiliateLinks = [];
  String? _error;

  final _contactController = TextEditingController();
  final _messageController = TextEditingController();
  String _contactType = 'email';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final billing = await AppSession.instance.api.getJson('/billing/status');
      final affiliates = await AppSession.instance.api.getList('/master/affiliate-links');
      setState(() {
        _billing = billing;
        _affiliateLinks = affiliates;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitConsultation() async {
    try {
      await AppSession.instance.api.postJson('/consultation', {
        'contact_type': _contactType,
        'contact_value': _contactController.text,
        'message': _messageController.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
          const SizedBox(height: 16),
          Text('アフィリエイト', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._affiliateLinks.map((link) {
            return ListTile(
              title: Text(link['title'] ?? ''),
              subtitle: Text(link['url'] ?? ''),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _trackAffiliate(link['id']),
            );
          }).toList(),
          const SizedBox(height: 16),
          Text('個人鑑定フォーム', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _contactType,
            items: const [
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'line', child: Text('LINE')),
              DropdownMenuItem(value: 'phone', child: Text('Phone')),
            ],
            onChanged: (value) => setState(() => _contactType = value ?? 'email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(labelText: '連絡先'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: '相談内容'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitConsultation,
              child: const Text('送信する'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
