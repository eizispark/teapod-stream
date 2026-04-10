import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_log_entry.dart';
import '../constants/app_constants.dart';

class AppSettings {
  final int socksPort;
  final LogLevel logLevel;
  final Set<String> excludedPackages;
  final bool splitTunnelingEnabled;
  final bool randomPort;
  final bool autoConnect;

  const AppSettings({
    this.socksPort = AppConstants.defaultSocksPort,
    this.logLevel = LogLevel.info,
    this.excludedPackages = const {},
    this.splitTunnelingEnabled = false,
    this.randomPort = true,
    this.autoConnect = false,
  });

  AppSettings copyWith({
    int? socksPort,
    LogLevel? logLevel,
    Set<String>? excludedPackages,
    bool? splitTunnelingEnabled,
    bool? randomPort,
    bool? autoConnect,
  }) {
    return AppSettings(
      socksPort: socksPort ?? this.socksPort,
      logLevel: logLevel ?? this.logLevel,
      excludedPackages: excludedPackages ?? this.excludedPackages,
      splitTunnelingEnabled:
          splitTunnelingEnabled ?? this.splitTunnelingEnabled,
      randomPort: randomPort ?? this.randomPort,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }
}

class SettingsService {
  static const _socksPortKey = 'socks_port';
  static const _logLevelKey = 'log_level';
  static const _excludedPackagesKey = 'excluded_packages';
  static const _splitTunnelingKey = 'split_tunneling_enabled';
  static const _randomPortKey = 'random_port';
  static const _autoConnectKey = 'auto_connect';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final excluded = (prefs.getStringList(_excludedPackagesKey) ?? []).toSet();
    return AppSettings(
      socksPort: prefs.getInt(_socksPortKey) ?? AppConstants.defaultSocksPort,
      logLevel: LogLevel.values.firstWhere(
        (e) => e.name == prefs.getString(_logLevelKey),
        orElse: () => LogLevel.info,
      ),
      excludedPackages: excluded,
      splitTunnelingEnabled: prefs.getBool(_splitTunnelingKey) ?? false,
      randomPort: prefs.getBool(_randomPortKey) ?? true,
      autoConnect: prefs.getBool(_autoConnectKey) ?? false,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_socksPortKey, settings.socksPort);
    await prefs.setString(_logLevelKey, settings.logLevel.name);
    await prefs.setStringList(
        _excludedPackagesKey, settings.excludedPackages.toList());
    await prefs.setBool(_splitTunnelingKey, settings.splitTunnelingEnabled);
    await prefs.setBool(_randomPortKey, settings.randomPort);
    await prefs.setBool(_autoConnectKey, settings.autoConnect);
  }
}
