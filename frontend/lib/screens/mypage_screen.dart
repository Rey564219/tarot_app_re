import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<Map<String, dynamic>> _affiliateLinks = [];
  String? _error;

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _contactType = 'email';
  bool _submittingConsultation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final billing = await AppSession.instance.api.getJson('/billing/status');
      final affiliates = await AppSession.instance.api.getList('/master/affiliate-links');
      if (!mounted) return;
      setState(() {
        _billing = Map<String, dynamic>.from(billing);
        _affiliateLinks = affiliates.whereType<Map<String, dynamic>>().toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _trackAffiliate(String? affiliateId) async {
    if (affiliateId == null || affiliateId.isEmpty) return;
    try {
      await AppSession.instance.api.postJson('/affiliate/click', {
        'affiliate_link_id': affiliateId,
        'placement': 'mypage',
      });
    } catch (e) {
      debugPrint('Failed to track affiliate click: $e');
    }
  }

  Future<void> _handleAffiliateTap(Map<String, dynamic> link) async {
    final url = link['url']?.toString() ?? '';
    final affiliateId = link['id']?.toString();
    await _trackAffiliate(affiliateId);
    if (url.isEmpty) {
      _showMessage('リンクが設定されていません。');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    _showMessage('リンクをコピーしました。ブラウザに貼り付けてください。\n$url');
  }

  Future<void> _submitConsultation() async {
    final contactValue = _contactController.text.trim();
    final message = _messageController.text.trim();
    if (contactValue.isEmpty) {
      _showMessage('連絡先を入力してください。');
      return;
    }

    if (mounted) {
      setState(() => _submittingConsultation = true);
    }
    try {
      await AppSession.instance.api.postJson('/consultation', {
        'contact_type': _contactType,
        'contact_value': contactValue,
        'message': message,
      });
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      _messageController.clear();
      _showMessage('個人鑑定の依頼を送信しました。追ってご連絡します。');
    } catch (e) {
      if (!mounted) return;
      _showMessage('送信に失敗しました: $e');
    } finally {
      if (!mounted) return;
      setState(() => _submittingConsultation = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }
    try {
      final dateTime = DateTime.parse(value.toString()).toLocal();
      final twoDigits = (int number) => number.toString().padLeft(2, '0');
      return '${dateTime.year}/${twoDigits(dateTime.month)}/${twoDigits(dateTime.day)} '
          '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildConsultationForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('個人鑑定フォーム', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _contactType,
            decoration: const InputDecoration(labelText: 'ご希望の連絡手段'),
            items: const [
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'line', child: Text('LINE')),
              DropdownMenuItem(value: 'phone', child: Text('電話')),
            ],
            onChanged: (value) => setState(() => _contactType = value ?? 'email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: '連絡先',
              hintText: 'メールアドレス、LINE IDなど',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: '相談したい内容',
              hintText: 'お悩みや希望する鑑定内容を記入してください',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submittingConsultation ? null : _submitConsultation,
              child: _submittingConsultation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('送信する'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliateSection(BuildContext context) {
    if (_affiliateLinks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('アフィリエイト', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._affiliateLinks.map((link) {
          final title = link['title']?.toString() ?? 'リンク';
          final provider = link['provider']?.toString();
          final url = link['url']?.toString() ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFAF6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text(title),
              subtitle: Text(
                provider != null && provider.isNotEmpty ? '$provider • $url' : url,
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _handleAffiliateTap(link),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = _billing;
    final subscriptionActive = billing?['subscription_active'] == true;
    final adsDisabled = billing?['ads_disabled'] == true;
    final expiresAt = _formatDate(billing?['subscription_expires_at']);
    final userId = AppSession.instance.userId ?? '取得中';

    return AppScaffold(
      title: 'My Page',
      subtitle: '契約状況やお問い合わせはこちら。',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loading ? null : _loadData,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Text('アカウント', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _statusCard('ユーザーID', userId),
          const SizedBox(height: 16),
          Text('サブスク状態', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _statusCard('サブスク', subscriptionActive ? '有効' : '未加入'),
          _statusCard('更新期限', expiresAt),
          _statusCard('広告表示', adsDisabled ? 'OFF（非表示）' : 'ON（表示）'),
          const SizedBox(height: 24),
          _buildAffiliateSection(context),
          if (_affiliateLinks.isNotEmpty) const SizedBox(height: 24),
          _buildConsultationForm(context),
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
