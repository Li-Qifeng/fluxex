import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 主题模式
          _SectionTitle(title: '外观', colorScheme: cs),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            child: Column(
              children: [
                _ThemeOptionTile(
                  icon: Icons.brightness_auto,
                  label: '跟随系统',
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => notifier.setThemeMode(ThemeMode.system),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOptionTile(
                  icon: Icons.brightness_7,
                  label: '浅色模式',
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => notifier.setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeOptionTile(
                  icon: Icons.brightness_2,
                  label: '深色模式',
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => notifier.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 字体大小
          _SectionTitle(title: '字体大小', colorScheme: cs),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            child: Column(
              children: [
                _ScaleOptionTile(
                  label: '标准',
                  subtitle: '1.0x',
                  selected: settings.textScale == 1.0,
                  onTap: () => notifier.setTextScale(1.0),
                ),
                const Divider(height: 1, indent: 16),
                _ScaleOptionTile(
                  label: '大',
                  subtitle: '1.1x',
                  selected: settings.textScale == 1.1,
                  onTap: () => notifier.setTextScale(1.1),
                ),
                const Divider(height: 1, indent: 16),
                _ScaleOptionTile(
                  label: '特大',
                  subtitle: '1.2x',
                  selected: settings.textScale == 1.2,
                  onTap: () => notifier.setTextScale(1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 缓存管理
          _SectionTitle(title: '存储', colorScheme: cs),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 0,
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            child: ListTile(
              leading: Icon(Icons.cleaning_services, color: cs.primary),
              title: const Text('清除缓存'),
              subtitle: const Text('清除话题缓存和浏览历史'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认清除'),
                    content: const Text('这将清除所有缓存的话题和浏览历史，确定吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final db = await DbHelper.database;
                  await db.delete('cached_topics');
                  await db.delete('browse_history');
                  if (context.mounted) {
                    AppToast.success(context, '缓存已清除');
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // 关于
          Center(
            child: Text(
              'FluxEx v0.1.7',
              style: TextStyle(
                fontSize: 13,
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionTitle({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? cs.primary : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: cs.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _ScaleOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ScaleOptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: selected ? cs.primary : cs.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check, color: cs.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
