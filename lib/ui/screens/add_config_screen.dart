import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../protocols/xray/vless_parser.dart';
import '../../providers/config_provider.dart';
import '../theme/app_colors.dart';
import 'qr_scan_screen.dart';

class AddConfigScreen extends ConsumerStatefulWidget {
  const AddConfigScreen({super.key});

  @override
  ConsumerState<AddConfigScreen> createState() => _AddConfigScreenState();
}

class _AddConfigScreenState extends ConsumerState<AddConfigScreen> {
  final _uriController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _openQrScan(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // URL input
                  TextField(
                    controller: _uriController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'vless://uuid@host:port?params#name\nvmess://base64json\ntrojan://pass@host:port\nss://encoded@host:port\nhttps://example.com/sub',
                      border: OutlineInputBorder(),
                      isDense: true,
                      helperText: 'Вставьте ссылку на конфигурацию или подписку',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _pasteFromClipboard,
                          icon: const Icon(Icons.paste_rounded, size: 18),
                          label: const Text('Вставить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _import,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Добавить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _openQrScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    ).then((value) {
      if (value != null && value is String) {
        setState(() {
          _uriController.text = value;
        });
        _processUri(value);
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _uriController.text = data.text!;
      await _import();
    }
  }

  Future<void> _import() async {
    final text = _uriController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Введите URL');
      return;
    }
    await _processUri(text);
  }

  Future<void> _processUri(String uri) async {
    setState(() { _loading = true; _error = null; });
    try {
      final parsed = Uri.parse(uri);

      if (parsed.scheme == 'http' || parsed.scheme == 'https') {
        // Subscription URL
        await ref.read(configProvider.notifier).addSubscriptionFromUrl(uri);
        if (mounted) Navigator.pop(context);
      } else {
        // Single config URI
        final config = VlessParser.parseUri(uri);
        if (config != null) {
          await ref.read(configProvider.notifier).addConfig(config);
          await ref.read(configProvider.notifier).setActiveConfig(config.id);
          if (mounted) Navigator.pop(context);
          return;
        }
        setState(() => _error = 'Не удалось распознать конфигурацию. Поддерживаются: vless://, vmess://, trojan://, ss://');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
