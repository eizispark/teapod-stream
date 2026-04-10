import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_log_entry.dart';
import '../models/dns_config.dart';
import '../constants/app_constants.dart';

class AppSettings {
  final int socksPort;
  final LogLevel logLevel;
  final Set<String> excludedPackages;
  final bool splitTunnelingEnabled;
  final bool randomPort;
  final bool autoConnect;
  final DnsMode dnsMode;
  final String dnsPreset;
  final String customDnsAddress;
  final String customDnsType;
  final bool enableUdp;
  final bool randomCredentials;

  const AppSettings({
    this.socksPort = AppConstants.defaultSocksPort,
    this.logLevel = LogLevel.info,
    this.excludedPackages = const {},
    this.splitTunnelingEnabled = false,
    this.randomPort = true,
    this.autoConnect = false,
    this.dnsMode = DnsMode.proxy,
    this.dnsPreset = 'cf_udp',
    this.customDnsAddress = '1.1.1.1',
    this.customDnsType = 'udp',
    this.enableUdp = true,
    this.randomCredentials = true,
  });

  AppSettings copyWith({
    int? socksPort,
    LogLevel? logLevel,
    Set<String>? excludedPackages,
    bool? splitTunnelingEnabled,
    bool? randomPort,
    bool? autoConnect,
    DnsMode? dnsMode,
    String? dnsPreset,
    String? customDnsAddress,
    String? customDnsType,
    bool? enableUdp,
    bool? randomCredentials,
  }) {
    return AppSettings(
      socksPort: socksPort ?? this.socksPort,
      logLevel: logLevel ?? this.logLevel,
      excludedPackages: excludedPackages ?? this.excludedPackages,
      splitTunnelingEnabled:
          splitTunnelingEnabled ?? this.splitTunnelingEnabled,
      randomPort: randomPort ?? this.randomPort,
      autoConnect: autoConnect ?? this.autoConnect,
      dnsMode: dnsMode ?? this.dnsMode,
      dnsPreset: dnsPreset ?? this.dnsPreset,
      customDnsAddress: customDnsAddress ?? this.customDnsAddress,
      customDnsType: customDnsType ?? this.customDnsType,
      enableUdp: enableUdp ?? this.enableUdp,
      randomCredentials: randomCredentials ?? this.randomCredentials,
    );
  }

  DnsServerConfig get dnsServer => DnsServerConfig.fromPreset(
    dnsPreset,
    customAddress: customDnsAddress,
    customType: customDnsType == 'doh' ? DnsType.doh : customDnsType == 'dot' ? DnsType.dot : DnsType.udp,
  );
}

class SettingsService {
  static const _socksPortKey = 'socks_port';
  static const _logLevelKey = 'log_level';
  static const _excludedPackagesKey = 'excluded_packages';
  static const _splitTunnelingKey = 'split_tunneling_enabled';
  static const _randomPortKey = 'random_port';
  static const _autoConnectKey = 'auto_connect';
  static const _dnsModeKey = 'dns_mode';
  static const _dnsPresetKey = 'dns_preset';
  static const _customDnsAddressKey = 'custom_dns_address';
  static const _customDnsTypeKey = 'custom_dns_type';
  static const _enableUdpKey = 'enable_udp';
  static const _randomCredentialsKey = 'random_credentials';

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
      dnsMode: DnsMode.values.firstWhere(
        (e) => e.name == prefs.getString(_dnsModeKey),
        orElse: () => DnsMode.proxy,
      ),
      dnsPreset: prefs.getString(_dnsPresetKey) ?? 'cf_udp',
      customDnsAddress: prefs.getString(_customDnsAddressKey) ?? '1.1.1.1',
      customDnsType: prefs.getString(_customDnsTypeKey) ?? 'udp',
      enableUdp: prefs.getBool(_enableUdpKey) ?? true,
      randomCredentials: prefs.getBool(_randomCredentialsKey) ?? true,
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
    await prefs.setString(_dnsModeKey, settings.dnsMode.name);
    await prefs.setString(_dnsPresetKey, settings.dnsPreset);
    await prefs.setString(_customDnsAddressKey, settings.customDnsAddress);
    await prefs.setString(_customDnsTypeKey, settings.customDnsType);
    await prefs.setBool(_enableUdpKey, settings.enableUdp);
    await prefs.setBool(_randomCredentialsKey, settings.randomCredentials);
  }
}
