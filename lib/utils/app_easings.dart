import 'package:flutter/animation.dart';

/// 全局统一缓动曲线 —— 参考 Apple Design + Emil Kowalski 设计工程
class AppEasings {
  AppEasings._();

  /// 强 ease-out：用于 UI 交互元素（按钮、卡片、弹窗入场）
  /// 比 CSS `ease-out` 更锐利，前段加速快
  static const easeOutStrong = Cubic(0.23, 1.0, 0.32, 1.0);

  /// 强 ease-in-out：用于元素在屏幕上的移动/变形
  static const easeInOutStrong = Cubic(0.77, 0.0, 0.175, 1.0);

  /// iOS 风格抽屉曲线
  static const easeDrawer = Cubic(0.32, 0.72, 0.0, 1.0);

  /// 按钮 press 释放
  static const easePressRelease = Cubic(0.23, 1.0, 0.32, 1.0);

  /// 按钮 press 按下（快速）
  static const easePress = Cubic(0.1, 0.0, 0.3, 1.0);
}