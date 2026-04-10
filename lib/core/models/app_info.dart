import 'dart:convert';
import 'package:flutter/material.dart';

class AppInfo {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final bool isExcluded;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    this.isExcluded = false,
  });

  AppInfo copyWith({bool? isExcluded}) => AppInfo(
        packageName: packageName,
        appName: appName,
        iconBase64: iconBase64,
        isExcluded: isExcluded ?? this.isExcluded,
      );

  ImageProvider? get iconImage {
    if (iconBase64 == null || iconBase64!.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(iconBase64!));
    } catch (_) {
      return null;
    }
  }
}
