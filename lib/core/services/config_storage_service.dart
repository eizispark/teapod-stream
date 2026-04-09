import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_config.dart';

class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime createdAt;
  final DateTime? lastFetchedAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.createdAt,
    this.lastFetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'createdAt': createdAt.toIso8601String(),
        'lastFetchedAt': lastFetchedAt?.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastFetchedAt: json['lastFetchedAt'] != null
            ? DateTime.parse(json['lastFetchedAt'] as String)
            : null,
      );

  Subscription copyWith({String? name}) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      url: url,
      createdAt: createdAt,
      lastFetchedAt: lastFetchedAt,
    );
  }
}

class ConfigStorageService {
  static const _configsKey = 'vpn_configs';
  static const _activeConfigKey = 'active_config_id';
  static const _subscriptionsKey = 'subscriptions';

  // ─── Configs ───

  Future<List<VpnConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_configsKey) ?? [];
    return raw
        .map((s) => VpnConfig.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConfigs(List<VpnConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _configsKey,
      configs.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> addConfig(VpnConfig config) async {
    final configs = await loadConfigs();
    configs.add(config);
    await saveConfigs(configs);
  }

  Future<void> removeConfig(String id) async {
    final configs = await loadConfigs();
    configs.removeWhere((c) => c.id == id);
    await saveConfigs(configs);
  }

  Future<void> updateConfig(VpnConfig updated) async {
    final configs = await loadConfigs();
    final idx = configs.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      configs[idx] = updated;
      await saveConfigs(configs);
    }
  }

  Future<String?> loadActiveConfigId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeConfigKey);
  }

  Future<void> saveActiveConfigId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeConfigKey);
    } else {
      await prefs.setString(_activeConfigKey, id);
    }
  }

  // ─── Subscriptions ───

  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_subscriptionsKey) ?? [];
    return raw
        .map((s) => Subscription.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSubscriptions(List<Subscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _subscriptionsKey,
      subs.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> addSubscription(Subscription sub) async {
    final subs = await loadSubscriptions();
    subs.add(sub);
    await saveSubscriptions(subs);
  }

  Future<void> updateSubscription(Subscription sub) async {
    final subs = await loadSubscriptions();
    final idx = subs.indexWhere((s) => s.id == sub.id);
    if (idx >= 0) {
      subs[idx] = sub;
      await saveSubscriptions(subs);
    }
  }

  Future<void> removeSubscription(String id) async {
    final subs = await loadSubscriptions();
    subs.removeWhere((s) => s.id == id);
    await saveSubscriptions(subs);
    // Also remove configs that belonged to this subscription
    final configs = await loadConfigs();
    configs.removeWhere((c) => c.subscriptionId == id);
    await saveConfigs(configs);
  }

  /// Find subscription by URL
  Future<Subscription?> findSubscriptionByUrl(String url) async {
    final subs = await loadSubscriptions();
    return subs.where((s) => s.url == url).firstOrNull;
  }

  /// Get configs that belong to a subscription
  Future<List<VpnConfig>> getConfigsForSubscription(String subscriptionId) async {
    final configs = await loadConfigs();
    return configs.where((c) => c.subscriptionId == subscriptionId).toList();
  }

  /// Get configs that are NOT from any subscription
  Future<List<VpnConfig>> getStandaloneConfigs() async {
    final configs = await loadConfigs();
    return configs.where((c) => c.subscriptionId == null).toList();
  }
}
