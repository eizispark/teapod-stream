import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/vpn_log_entry.dart';
import '../../core/services/log_service.dart';
import '../theme/app_colors.dart';
import '../widgets/log_entry_widget.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;
  final Set<LogLevel> _selectedLevels = {
    LogLevel.error,
    LogLevel.warning,
    LogLevel.info,
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _copyToClipboard(List<VpnLogEntry> logs) async {
    final text = logs.map((e) => '[${e.timestamp.toIso8601String()}] [${e.level.name.toUpperCase()}] ${e.message}').join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Логи скопированы в буфер обмена'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logServiceProvider);
    final filtered = _selectedLevels.isEmpty
        ? logs
        : logs.where((e) => _selectedLevels.contains(e.level)).toList();

    // Auto scroll when new entries arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoScroll) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи VPN'),
        actions: [
          // Copy logs
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Копировать',
            onPressed: filtered.isEmpty ? null : () => _copyToClipboard(filtered),
          ),
          // Clear logs
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              ref.read(logServiceProvider.notifier).clear();
            },
          ),
          // Toggle auto-scroll
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom_rounded
                  : Icons.pause_rounded,
              color: _autoScroll ? AppColors.primary : null,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
        ],
      ),
      body: Container(
        color: AppColors.surface,
        child: Column(
          children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                _LevelCount(
                  logs: logs,
                  level: LogLevel.error,
                  color: AppColors.logError,
                ),
                const SizedBox(width: 16),
                _LevelCount(
                  logs: logs,
                  level: LogLevel.warning,
                  color: AppColors.logWarning,
                ),
                const SizedBox(width: 16),
                _LevelCount(
                  logs: logs,
                  level: LogLevel.info,
                  color: AppColors.logInfo,
                ),
                const SizedBox(width: 16),
                _LevelCount(
                  logs: logs,
                  level: LogLevel.debug,
                  color: AppColors.textSecondary,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} записей',
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ERROR',
                    selected: _selectedLevels.contains(LogLevel.error),
                    onTap: () => setState(() {
                      if (_selectedLevels.contains(LogLevel.error)) {
                        _selectedLevels.remove(LogLevel.error);
                      } else {
                        _selectedLevels.add(LogLevel.error);
                      }
                    }),
                    color: AppColors.logError,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'WARN',
                    selected: _selectedLevels.contains(LogLevel.warning),
                    onTap: () => setState(() {
                      if (_selectedLevels.contains(LogLevel.warning)) {
                        _selectedLevels.remove(LogLevel.warning);
                      } else {
                        _selectedLevels.add(LogLevel.warning);
                      }
                    }),
                    color: AppColors.logWarning,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'INFO',
                    selected: _selectedLevels.contains(LogLevel.info),
                    onTap: () => setState(() {
                      if (_selectedLevels.contains(LogLevel.info)) {
                        _selectedLevels.remove(LogLevel.info);
                      } else {
                        _selectedLevels.add(LogLevel.info);
                      }
                    }),
                    color: AppColors.logInfo,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'DEBUG',
                    selected: _selectedLevels.contains(LogLevel.debug),
                    onTap: () => setState(() {
                      if (_selectedLevels.contains(LogLevel.debug)) {
                        _selectedLevels.remove(LogLevel.debug);
                      } else {
                        _selectedLevels.add(LogLevel.debug);
                      }
                    }),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Log list
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Логи пусты',
                      style: TextStyle(color: AppColors.textDisabled),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is UserScrollNotification) {
                        // Pause auto-scroll on user scroll up
                        if (_scrollController.hasClients) {
                          final isAtBottom =
                              _scrollController.position.pixels >=
                                  _scrollController.position.maxScrollExtent -
                                      50;
                          if (!isAtBottom && _autoScroll) {
                            setState(() => _autoScroll = false);
                          }
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) =>
                          LogEntryWidget(entry: filtered[i]),
                    ),
                  ),
          ),
        ],
        ),
      ),
      floatingActionButton: !_autoScroll
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() => _autoScroll = true);
                _scrollToBottom();
              },
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.vertical_align_bottom_rounded,
                  color: AppColors.primary),
            )
          : null,
    );
  }
}

class _LevelCount extends StatelessWidget {
  final List<VpnLogEntry> logs;
  final LogLevel level;
  final Color color;

  const _LevelCount({
    required this.logs,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final count = logs.where((e) => e.level == level).length;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (color ?? AppColors.primary).withValues(alpha: 0.15)
        : AppColors.surfaceElevated;
    final textColor = selected
        ? (color ?? AppColors.primary)
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? (color ?? AppColors.primary) : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
