class AppInfo {
  final String packageName;
  final String appName;
  final bool isExcluded;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.isExcluded = false,
  });

  AppInfo copyWith({bool? isExcluded}) => AppInfo(
        packageName: packageName,
        appName: appName,
        isExcluded: isExcluded ?? this.isExcluded,
      );
}
