import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/settings_service.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  final _service = SettingsService();

  @override
  Future<AppSettings> build() => _service.load();

  Future<void> save(AppSettings settings) async {
    await _service.save(settings);
    state = AsyncData(settings);
  }

  Future<void> toggleExcludedPackage(String package) async {
    final current = state.maybeWhen(data: (d) => d, orElse: () => null);
    if (current == null) return;
    final excluded = Set<String>.from(current.excludedPackages);
    if (excluded.contains(package)) {
      excluded.remove(package);
    } else {
      excluded.add(package);
    }
    await save(current.copyWith(excludedPackages: excluded));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
