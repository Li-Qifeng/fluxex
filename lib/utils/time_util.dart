/// 相对时间格式化工具
String formatRelativeTime(int timestamp) {
  final now = DateTime.now();
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds}秒前';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}分钟前';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}小时前';
  } else if (diff.inDays < 30) {
    return '${diff.inDays}天前';
  } else if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()}个月前';
  } else {
    return '${(diff.inDays / 365).floor()}年前';
  }
}

/// 绝对时间格式化
String formatAbsoluteTime(int timestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final now = DateTime.now();
  final isThisYear = dt.year == now.year;
  if (isThisYear) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
