import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/vpn_log_entry.dart';
import '../../core/services/settings_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vpn_provider.dart';
import '../theme/app_colors.dart';
import 'split_tunnel_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final vpnState = ref.watch(vpnProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (settings) => _SettingsBody(
          settings: settings,
          isConnected: vpnState.isConnected,
          onUpdate: (s) => ref.read(settingsProvider.notifier).save(s),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  final AppSettings settings;
  final bool isConnected;
  final void Function(AppSettings) onUpdate;

  const _SettingsBody({
    required this.settings,
    required this.isConnected,
    required this.onUpdate,
  });

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late final TextEditingController _socksPortCtrl;

  @override
  void initState() {
    super.initState();
    _socksPortCtrl =
        TextEditingController(text: widget.settings.socksPort.toString());
  }

  @override
  void dispose() {
    _socksPortCtrl.dispose();
    super.dispose();
  }

  void _updatePorts() {
    final socks = int.tryParse(_socksPortCtrl.text);
    if (socks != null) {
      widget.onUpdate(widget.settings.copyWith(
        socksPort: socks.clamp(1024, 65535),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection section
        _SectionHeader('Подключение'),
        const SizedBox(height: 8),
        _SettingsCard(
          children: [
            SwitchListTile(
              title: const Text(
                'Случайный порт',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
              subtitle: const Text(
                'Использовать случайный порт при каждом подключении',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              value: widget.settings.randomPort,
              onChanged: widget.isConnected
                  ? null
                  : (v) => widget.onUpdate(
                      widget.settings.copyWith(randomPort: v)),
            ),
            if (!widget.settings.randomPort) ...[
              const _Divider(),
              _PortField(
                label: 'SOCKS5 порт',
                hint: '10808',
                controller: _socksPortCtrl,
                enabled: !widget.isConnected,
                onChanged: (_) => _updatePorts(),
              ),
            ],
          ],
        ),
        if (widget.isConnected) ...[
          const SizedBox(height: 6),
          const _DisabledNote('Настройки нельзя изменить во время подключения'),
        ],

        const SizedBox(height: 20),

        // Logging section
        _SectionHeader('Логирование'),
        const SizedBox(height: 8),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Уровень логов',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        Text(
                          'Verbose логи могут снизить производительность',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<LogLevel>(
                    value: widget.settings.logLevel,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: const SizedBox(),
                    items: LogLevel.values
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              l.name[0].toUpperCase() + l.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (l) {
                      if (l != null) {
                        widget.onUpdate(
                            widget.settings.copyWith(logLevel: l));
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Split tunneling
        _SectionHeader('Сплит-туннелирование'),
        const SizedBox(height: 8),
        _SettingsCard(
          children: [
            SwitchListTile(
              title: const Text(
                'Включить сплит-туннелирование',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              ),
              subtitle: const Text(
                'Выберите приложения, трафик которых НЕ будет проходить через VPN',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              value: widget.settings.splitTunnelingEnabled,
              onChanged: widget.isConnected
                  ? null
                  : (v) => widget.onUpdate(
                      widget.settings.copyWith(splitTunnelingEnabled: v)),
            ),
            if (widget.settings.splitTunnelingEnabled) ...[
              const _Divider(),
              ListTile(
                title: const Text(
                  'Исключённые приложения',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                ),
                subtitle: Text(
                  '${widget.settings.excludedPackages.length} приложений исключено',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
                enabled: !widget.isConnected,
                onTap: widget.isConnected
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SplitTunnelScreen(),
                          ),
                        ),
              ),
            ],
          ],
        ),
        if (widget.isConnected && widget.settings.splitTunnelingEnabled) ...[
          const SizedBox(height: 6),
          const _DisabledNote(
              'Сплит-туннелирование нельзя изменить во время подключения'),
        ],

        const SizedBox(height: 20),

        // Info section
        _SectionHeader('О приложении'),
        const SizedBox(height: 8),
        _SettingsCard(
          children: [
            const ListTile(
              title: Text(
                'TeapodStream',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'VPN клиент с поддержкой xray',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                'v1.0.0',
                style: TextStyle(color: AppColors.textDisabled),
              ),
            ),
            const _Divider(),
            ListTile(
              title: const Text(
                'Конфиденциальность SOCKS',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Прокси защищён случайными учётными данными. '
                'Только tun2socks имеет доступ к SOCKS прокси.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.connected.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppColors.connected, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }
}

class _PortField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final void Function(String) onChanged;

  const _PortField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    enabled ? AppColors.textPrimary : AppColors.textDisabled,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              onEditingComplete: () => FocusScope.of(context).unfocus(),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledNote extends StatelessWidget {
  final String text;
  const _DisabledNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.connecting, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.connecting,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
