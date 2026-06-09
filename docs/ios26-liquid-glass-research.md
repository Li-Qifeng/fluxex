# iOS 26 液态玻璃 (Liquid Glass) 与 Flutter 兼容性调研

## 一、iOS 26 Liquid Glass 是什么

WWDC 2025 发布的 iOS 26 引入全新设计语言 **Liquid Glass（液态玻璃）**：
- **视觉效果**：半透明、折射、动态模糊的玻璃质感 UI 元素
- **技术实现**：基于 UIKit/SwiftUI 的原生 `Material` 系统，使用 Metal GPU 加速的实时模糊和折射
- **核心 API**：SwiftUI 的 `.glassEffect()` modifier、`UIVisualEffectView` 增强版
- **自适应**：根据背后内容自动调整色调、亮度、对比度
- **交互响应**：对触摸、设备倾斜做出流体形变动画

## 二、Flutter 能否使用原生 Liquid Glass

### 结论：❌ 不能直接使用

| 方面 | 说明 |
|---|---|
| **渲染引擎** | Flutter 使用 Skia/Impeller 自绘引擎，不走 UIKit 视图树 |
| **平台视图** | `PlatformView` 可嵌入原生 UIView，但无法与 Flutter widget 自由混合叠加 |
| **BackdropFilter** | Flutter 有 `BackdropFilter`，但底层是 Skia 的 `ImageFilter.blur()`，不是 iOS 原生 `UIVisualEffectView` |
| **性能差异** | 原生 Liquid Glass 使用 Metal shader 实时折射；Flutter 的 blur 是 CPU/GPU 混合，复杂场景有性能差距 |

### 理论上的桥接方案（不推荐）

1. **PlatformView + UIVisualEffectView**：在 Flutter 上层覆盖原生毛玻璃 UIView
   - 问题：z-order 管理复杂、触摸事件穿透困难、与 Flutter 动画不同步
2. **Method Channel 调用截图 + 原生模糊**：截取 Flutter 画面 → 传给原生做模糊 → 返回显示
   - 问题：延迟高、无法实现实时交互效果

## 三、Flutter 近似方案

### 方案 A：BackdropFilter + 半透明层（推荐）

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: child,
    ),
  ),
)
```

**效果**：类似 iOS 之前的毛玻璃效果（frosted glass），但缺少 Liquid Glass 的折射和流体形变。

### 方案 B：第三方包

| 包名 | 效果 | 适用性 |
|---|---|---|
| `glassmorphism_ui` | Glassmorphism 效果 | ✅ 可用，但效果固定 |
| `flutter_blur` | 高级模糊 | ⚠️ 性能一般 |
| `shaders` + Fragment Shader | 自定义 GLSL shader | ✅ 最接近原生，但需手写 shader |

### 方案 C：Impeller Fragment Shader（最接近 Liquid Glass）

Flutter 3.x 的 Impeller 引擎支持自定义 Fragment Shader：
- 编写 GLSL shader 实现折射、色散、动态模糊
- 通过 `FragmentProgram.fromAsset()` 加载
- 可以实现接近 Liquid Glass 的视觉效果
- **缺点**：开发成本高、需要 shader 编程经验、仅支持 Impeller（iOS/Android）

## 四、对 FluxEx 的建议

### 现阶段（Flutter 3.24.5）
- **可行**：使用 `BackdropFilter` 实现 AppBar、BottomSheet、Dialog 的毛玻璃效果
- **效果**：接近 iOS 之前的 `UIVisualEffectView` 风格，不是真正的 Liquid Glass
- **成本**：低，改动量小

### 中期（Flutter 3.27+ / Impeller 稳定后）
- **可行**：使用 Fragment Shader 实现自定义折射效果
- **效果**：接近 Liquid Glass 的视觉体验
- **成本**：中，需要 shader 开发

### 长期（Flutter 原生支持）
- 等待 Flutter 团队是否会跟进 iOS 26 Liquid Glass 的平台集成
- 关注 [flutter/flutter#170623](https://github.com/flutter/flutter) 等相关 issue

## 五、结论

| 维度 | 评估 |
|---|---|
| 能否实现原生 Liquid Glass | ❌ 不能 |
| 能否近似实现 | ✅ 可以，BackdropFilter 达到 70% 效果 |
| 推荐方案 | 方案 A（BackdropFilter）+ 未来升级到 Fragment Shader |
| 开发成本 | 低（BackdropFilter）→ 中（Fragment Shader）|
| 性能影响 | BackdropFilter 在复杂列表中可能掉帧，需谨慎使用 |

**建议**：先在 AppBar 和 Dialog 上试水 BackdropFilter 毛玻璃效果，观察性能反馈后再决定是否全面铺开。
