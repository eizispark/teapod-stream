import '../models/vpn_config.dart';
import '../models/vpn_stats.dart';
import '../models/vpn_log_entry.dart';

enum VpnState { disconnected, connecting, connected, disconnecting, error }

abstract class VpnEngine {
  String get protocolName;

  Stream<VpnState> get stateStream;
  Stream<VpnStats> get statsStream;
  Stream<VpnLogEntry> get logStream;

  VpnState get currentState;
  VpnStats get currentStats;

  Future<void> connect(VpnConfig config, VpnEngineOptions options);
  Future<void> disconnect();

  Future<int?> pingConfig(VpnConfig config);
  bool supportsConfig(VpnConfig config);
}

class VpnEngineOptions {
  final int socksPort;
  final int httpPort;
  final String socksUser;
  final String socksPassword;
  final Set<String> excludedPackages;
  final LogLevel logLevel;
  final bool enableUdp;

  const VpnEngineOptions({
    required this.socksPort,
    required this.httpPort,
    required this.socksUser,
    required this.socksPassword,
    this.excludedPackages = const {},
    this.logLevel = LogLevel.info,
    this.enableUdp = true,
  });
}
