import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 从 URL 下载图片到临时目录，返回本地文件路径
Future<String?> downloadImage(String url) async {
  try {
    final dir = await getTemporaryDirectory();
    final name = 'fluxex_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${dir.path}/$name';
    await Dio().download(url, path);
    return path;
  } catch (_) {
    return null;
  }
}

/// 保存图片到相册
Future<bool> saveImageToGallery(String url) async {
  try {
    final path = await downloadImage(url);
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists()) return false;
    // 请求权限并保存
    if (!await Gal.requestAccess()) return false;
    await Gal.putImage(path);
    // 清理临时文件
    try {
      await file.delete();
    } catch (_) {}
    return true;
  } catch (_) {
    return false;
  }
}

/// 分享图片文件（而非仅 URL）
Future<void> shareImageFile(String url) async {
  try {
    final path = await downloadImage(url);
    if (path == null) {
      // Fallback: 分享 URL
      await Share.share(url);
      return;
    }
    await Share.shareXFiles(
      [XFile(path)],
      text: '分享图片',
    );
    // 清理临时文件（短暂延迟确保分享完成）
    Future.delayed(const Duration(seconds: 5), () {
      File(path).delete();
    });
  } catch (_) {
    // Fallback
    await Share.share(url);
  }
}