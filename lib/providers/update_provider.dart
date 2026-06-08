import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final bool hasUpdate;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });
}

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final updateInfoProvider = FutureProvider<UpdateInfo>((ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  final response = await Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/vnd.github+json'},
  )).get('https://api.github.com/repos/Li-Qifeng/fluxex/releases/latest');

  final data = response.data as Map<String, dynamic>;
  final latestTag = (data['tag_name'] as String? ?? '').trim();
  final latestVersion = latestTag.startsWith('v') ? latestTag.substring(1) : latestTag;
  final currentVersion = packageInfo.version;

  return UpdateInfo(
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    releaseUrl: data['html_url'] as String? ?? 'https://github.com/Li-Qifeng/fluxex/releases',
    releaseNotes: data['body'] as String? ?? '',
    hasUpdate: _compareVersions(latestVersion, currentVersion) > 0,
  );
});

int _compareVersions(String left, String right) {
  final leftParts = _parseVersion(left);
  final rightParts = _parseVersion(right);
  final length = leftParts.length > rightParts.length ? leftParts.length : rightParts.length;
  for (var i = 0; i < length; i++) {
    final a = i < leftParts.length ? leftParts[i] : 0;
    final b = i < rightParts.length ? rightParts[i] : 0;
    if (a != b) return a.compareTo(b);
  }
  return 0;
}

List<int> _parseVersion(String version) {
  return version
      .split(RegExp(r'[.+-]'))
      .take(3)
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
