import 'package:flutter/material.dart';

void showImageViewer(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 64),
                  SizedBox(height: 12),
                  Text('图片加载失败', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
