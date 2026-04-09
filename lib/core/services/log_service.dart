import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/vpn_log_entry.dart';

class LogService extends Notifier<List<VpnLogEntry>> {
  @override
  List<VpnLogEntry> build() => [];

  void add(VpnLogEntry entry) {
    final current = [...state, entry];
    if (current.length > AppConstants.maxLogEntries) {
      state = current.sublist(current.length - AppConstants.maxLogEntries);
    } else {
      state = current;
    }
  }

  void addInfo(String message, {String? source}) =>
      add(VpnLogEntry.info(message, source: source));

  void addError(String message, {String? source}) =>
      add(VpnLogEntry.error(message, source: source));

  void addWarning(String message, {String? source}) =>
      add(VpnLogEntry.warning(message, source: source));

  void addDebug(String message, {String? source}) =>
      add(VpnLogEntry.debug(message, source: source));

  void clear() => state = [];
}

final logServiceProvider =
    NotifierProvider<LogService, List<VpnLogEntry>>(LogService.new);
