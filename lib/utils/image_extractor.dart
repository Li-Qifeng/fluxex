import 'package:flutter/material.dart';

List<String> extractImageUrls(String html) {
  final regex = RegExp(r"""<img[^>]+src=["']([^"']+)["']""", caseSensitive: false);
  final matches = regex.allMatches(html);
  return matches.map((m) => m.group(1)!).where((url) => url.isNotEmpty).toList();
}
