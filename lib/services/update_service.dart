
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final String githubUser;
  final String githubRepo;

  UpdateService({required this.githubUser, required this.githubRepo});

  Future<Map<String, dynamic>?> fetchLatestRelease() async {
    final url = 'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to fetch latest release: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching latest release: $e');
      return null;
    }
  }

  Future<bool> isUpdateAvailable() async {
    final latestRelease = await fetchLatestRelease();
    if (latestRelease == null) {
      return false;
    }

    final currentPackageInfo = await PackageInfo.fromPlatform();
    final currentVersion = currentPackageInfo.version;
    final latestVersion = latestRelease['tag_name'] as String;

    // Simple version comparison (e.g., v1.0.0 vs v1.0.1)
    // This can be made more robust for complex versioning schemes
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  int _compareVersions(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (i >= latestParts.length) return 1; // Current is longer, assume newer
      if (currentParts[i] < latestParts[i]) return -1;
      if (currentParts[i] > latestParts[i]) return 1;
    }
    if (latestParts.length > currentParts.length) return -1; // Latest is longer, assume newer
    return 0;
  }

  Future<void> launchDownloadUrl(String? downloadUrl) async {
    if (downloadUrl != null && await canLaunchUrl(Uri.parse(downloadUrl))) {
      await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch download URL: $downloadUrl');
    }
  }
}
