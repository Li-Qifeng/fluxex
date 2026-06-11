import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// iOS 26 风格玻璃搜索框
class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const GlassSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassContainer(
      shape: const LiquidRoundedSuperellipse(borderRadius: 22),
      settings: const LiquidGlassSettings(
        thickness: 18,
        blur: 14,
        refractiveIndex: 1.55,
        chromaticAberration: 0.1,
        lightIntensity: 0.55,
        saturation: 0.85,
        ambientStrength: 0.3,
        glassColor: Color.from(alpha: 0.08, red: 1, green: 1, blue: 1),
      ),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller ?? TextEditingController(),
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    controller?.clear();
                    onClear?.call();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                );
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          ),
        ),
      ),
    );
  }
}
