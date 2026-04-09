class VpnStats {
  final int uploadBytes;
  final int downloadBytes;
  final int uploadSpeedBps;
  final int downloadSpeedBps;
  final Duration connectedDuration;
  final String? connectedServer;

  const VpnStats({
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.uploadSpeedBps = 0,
    this.downloadSpeedBps = 0,
    this.connectedDuration = Duration.zero,
    this.connectedServer,
  });

  VpnStats copyWith({
    int? uploadBytes,
    int? downloadBytes,
    int? uploadSpeedBps,
    int? downloadSpeedBps,
    Duration? connectedDuration,
    String? connectedServer,
  }) {
    return VpnStats(
      uploadBytes: uploadBytes ?? this.uploadBytes,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      uploadSpeedBps: uploadSpeedBps ?? this.uploadSpeedBps,
      downloadSpeedBps: downloadSpeedBps ?? this.downloadSpeedBps,
      connectedDuration: connectedDuration ?? this.connectedDuration,
      connectedServer: connectedServer ?? this.connectedServer,
    );
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
