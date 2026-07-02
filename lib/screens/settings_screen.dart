import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keywordController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();

  static const _accentColors = [
    Color(0xFF446CB3), // 经典蓝
    Color(0xFFE53935), // 红色
    Color(0xFF7B1FA2), // 紫色
    Color(0xFF00897B), // 墨绿
    Color(0xFFFF6F00), // 橙色
    Color(0xFF5C6BC0), // 靛蓝
    Color(0xFF26A69A), // 青绿
    Color(0xFFEF5350), // 珊瑚
  ];

  @override
  void dispose() {
    _keywordController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // Sync proxy controllers with current values
    _proxyHostController.text = settings.proxyHost;
    _proxyPortController.text =
        settings.proxyPort > 0 ? settings.proxyPort.toString() : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── 用户信息卡片 ──
          Consumer(
            builder: (context, ref, child) {
              final auth = ref.watch(authProvider);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: auth.isLoggedIn
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          child: Icon(
                            auth.isLoggedIn
                                ? Icons.person
                                : Icons.person_outline,
                            color: auth.isLoggedIn
                                ? cs.onPrimaryContainer
                                : cs.outline,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.isLoggedIn
                                    ? (auth.username ?? '已登录')
                                    : '未登录',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (auth.username != null)
                                Text(
                                  auth.username!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (auth.isLoggedIn)
                          IconButton(
                            icon: const Icon(Icons.logout, size: 20),
                            color: cs.error,
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              AppToast.success(context, '已退出登录');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── 外观 ──
          _SectionTitle(title: '外观', colorScheme: cs),
          _SettingsCard(
            cs: cs,
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
          const SizedBox(height: 8),

          // ── 主题色 ──
          _SectionTitle(title: '主题色', colorScheme: cs),
          _SettingsCard(
            cs: cs,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _accentColors.map((color) {
                    final selected =
                        color.value == settings.accentColorValue;
                    return GestureDetector(
                      onTap: () => notifier.setAccentColor(color.value),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: cs.onSurface, width: 2.5)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? Icon(Icons.check,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black54
                                    : Colors.white,
                                size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 字体大小 ──
          _SectionTitle(title: '字体大小', colorScheme: cs),
          _SettingsCard(
            cs: cs,
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
          const SizedBox(height: 8),

          // ── 图片质量 ──
          _SectionTitle(title: '图片质量', colorScheme: cs),
          _SettingsCard(
            cs: cs,
            children: [
              _ImageQualityTile(
                label: '原始',
                subtitle: '加载原图（流量消耗大）',
                value: 'original',
                selected: settings.imageQuality == 'original',
                onTap: () => notifier.setImageQuality('original'),
              ),
              const Divider(height: 1, indent: 16),
              _ImageQualityTile(
                label: '高',
                subtitle: '1920px 缩放',
                value: 'high',
                selected: settings.imageQuality == 'high',
                onTap: () => notifier.setImageQuality('high'),
              ),
              const Divider(height: 1, indent: 16),
              _ImageQualityTile(
                label: '中',
                subtitle: '960px 缩放',
                value: 'medium',
                selected: settings.imageQuality == 'medium',
                onTap: () => notifier.setImageQuality('medium'),
              ),
              const Divider(height: 1, indent: 16),
              _ImageQualityTile(
                label: '低',
                subtitle: '480px 缩放（省流）',
                value: 'low',
                selected: settings.imageQuality == 'low',
                onTap: () => notifier.setImageQuality('low'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 代理设置 ──
          _SectionTitle(title: '网络代理', colorScheme: cs),
          _SettingsCard(
            cs: cs,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proxyHostController,
                            decoration: const InputDecoration(
                              hintText: '代理地址',
                              labelText: '主机',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _proxyPortController,
                            decoration: const InputDecoration(
                              hintText: '端口',
                              labelText: '端口',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              final host =
                                  _proxyHostController.text.trim();
                              final portStr =
                                  _proxyPortController.text.trim();
                              final port = int.tryParse(portStr) ?? 0;
                              if (host.isNotEmpty && port > 0) {
                                notifier.setProxy(host, port);
                                AppToast.success(context, '代理已设置');
                              } else {
                                AppToast.error(context, '请输入有效的代理地址和端口');
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('保存代理'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            notifier.clearProxy();
                            _proxyHostController.clear();
                            _proxyPortController.clear();
                            AppToast.info(context, '代理已清除');
                          },
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                    if (settings.proxyHost.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '当前代理: ${settings.proxyHost}:${settings.proxyPort}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 存储 ──
          _SectionTitle(title: '存储', colorScheme: cs),
          _SettingsCard(
            cs: cs,
            children: [
              ListTile(
                leading:
                    Icon(Icons.cleaning_services, color: cs.primary),
                title: const Text('清除缓存'),
                subtitle: const Text('清除话题缓存和浏览历史'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认清除'),
                      content: const Text(
                          '这将清除所有缓存的话题和浏览历史，确定吗？'),
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
            ],
          ),
          const SizedBox(height: 8),

          // ── 关键词过滤 ──
          _SectionTitle(title: '关键词过滤', colorScheme: cs),
          _SettingsCard(
            cs: cs,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (settings.blockedKeywords.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            settings.blockedKeywords.map((kw) {
                          return Chip(
                            label: Text(kw),
                            onDeleted: () =>
                                notifier.removeBlockedKeyword(kw),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        '暂无屏蔽关键词',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            decoration: const InputDecoration(
                              hintText: '输入关键词',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final kw =
                                _keywordController.text.trim();
                            if (kw.isNotEmpty) {
                              notifier.addBlockedKeyword(kw);
                              _keywordController.clear();
                            }
                          },
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 关于 ──
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              final build = snapshot.data?.buildNumber ?? '';
              final label = version.isNotEmpty
                  ? 'FluxEx v$version${build.isNotEmpty ? '+$build' : ''}'
                  : 'FluxEx';
              return Center(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: cs.outline),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable helpers ──

class _SettingsCard extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> children;
  const _SettingsCard({required this.cs, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(children: children),
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
      trailing:
          selected ? Icon(Icons.check, color: cs.primary, size: 20) : null,
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
      trailing:
          selected ? Icon(Icons.check, color: cs.primary, size: 20) : null,
      onTap: onTap,
    );
  }
}

class _ImageQualityTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ImageQualityTile({
    required this.label,
    required this.subtitle,
    required this.value,
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
      trailing:
          selected ? Icon(Icons.check, color: cs.primary, size: 20) : null,
      onTap: onTap,
    );
  }
}