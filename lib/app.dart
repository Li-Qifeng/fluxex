import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/nodes_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/login_webview_screen.dart';
import 'screens/reply_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/node_detail_screen.dart';
import 'screens/member_detail_screen.dart';
import 'screens/topic_detail_screen.dart';
import 'screens/create_topic_screen.dart';
import 'screens/followed_nodes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/read_later_screen.dart';
import 'screens/followed_members_screen.dart';
import 'screens/drafts_screen.dart';
import 'widgets/constrained_content.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(child: const HomeScreen(), key: state.pageKey),
        ),
        GoRoute(
          path: '/nodes',
          pageBuilder: (context, state) => NoTransitionPage(child: const NodesScreen(), key: state.pageKey),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => NoTransitionPage(child: const SearchScreen(), key: state.pageKey),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => NoTransitionPage(child: const ProfileScreen(), key: state.pageKey),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bookmarks',
      pageBuilder: (context, state) => CupertinoPage(child: const BookmarksScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reply/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CupertinoPage(child: ReplyScreen(topicId: id), key: state.pageKey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      pageBuilder: (context, state) => CupertinoPage(child: const LoginWebViewScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications',
      pageBuilder: (context, state) => CupertinoPage(child: const NotificationsScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/topic/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CupertinoPage(child: TopicDetailScreen(topicId: id), key: state.pageKey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/member/:username',
      pageBuilder: (context, state) {
        final username = state.pathParameters['username']!;
        return CupertinoPage(child: MemberDetailScreen(username: username), key: state.pageKey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/node/:name',
      pageBuilder: (context, state) {
        final name = state.pathParameters['name']!;
        return CupertinoPage(child: NodeDetailScreen(nodeName: name), key: state.pageKey);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/create-topic',
      pageBuilder: (context, state) => CupertinoPage(child: const CreateTopicScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/followed-nodes',
      pageBuilder: (context, state) => CupertinoPage(child: const FollowedNodesScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      pageBuilder: (context, state) => CupertinoPage(child: const SettingsScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/read-later',
      pageBuilder: (context, state) => CupertinoPage(child: const ReadLaterScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/followed-members',
      pageBuilder: (context, state) => CupertinoPage(child: const FollowedMembersScreen(), key: state.pageKey),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/drafts',
      pageBuilder: (context, state) => CupertinoPage(child: const DraftsScreen(), key: state.pageKey),
    ),
  ],
);

class V2exApp extends ConsumerStatefulWidget {
  const V2exApp({super.key});

  @override
  ConsumerState<V2exApp> createState() => _V2exAppState();
}

class _V2exAppState extends ConsumerState<V2exApp> {
  @override
  void initState() {
    super.initState();
    _setHighRefreshRate();
  }

  Future<void> _setHighRefreshRate() async {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }

  ThemeData _buildTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
    );
    final rawTextTheme = GoogleFonts.notoSansTextTheme(base.textTheme);
    final textTheme = rawTextTheme.copyWith(
      displayLarge: rawTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w500),
      displayMedium: rawTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w500),
      displaySmall: rawTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w500),
      headlineLarge: rawTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: rawTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: rawTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: rawTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: rawTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: rawTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: rawTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: rawTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: rawTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: rawTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: rawTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: rawTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.0),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (dynamic lightDynamic, dynamic darkDynamic) {
        final fallbackLight = ColorScheme.fromSeed(
          seedColor: settings.accentColor,
          brightness: Brightness.light,
        );
        final fallbackDark = ColorScheme.fromSeed(
          seedColor: settings.accentColor,
          brightness: Brightness.dark,
        );
        return MaterialApp.router(
          title: 'FluxEx',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(lightDynamic?.harmonized() ?? fallbackLight),
          darkTheme: _buildTheme(darkDynamic?.harmonized() ?? fallbackDark),
          themeMode: settings.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.textScale),
              ),
              child: GlassTheme(
                data: GlassThemeData.simple(
                  blur: 6,
                  thickness: 24,
                  quality: GlassQuality.standard,
                  chromaticAberration: 0.15,
                  lightIntensity: 0.75,
                  ambientStrength: 0.15,
                  refractiveIndex: 1.42,
                  saturation: 1.0,
                  borderRadius: 16,
                ),
                child: child!,
              ),
            );
          },
          routerConfig: appRouter,
        );
      },
    );
  }
}

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/nodes')) currentIndex = 1;
    if (location.startsWith('/search')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 浅色模式：玻璃层底色更暗、更不透明，确保按钮可见
    // 深色模式：玻璃层底色稍亮，保持玻璃质感
    final glassColor = isDark
        ? const Color.from(alpha: 0.18, red: 1, green: 1, blue: 1)
        : const Color.from(alpha: 0.35, red: 0.95, green: 0.95, blue: 0.95);
    final unselectedColor = isDark
        ? const Color.from(alpha: 0.55, red: 1, green: 1, blue: 1)
        : const Color.from(alpha: 0.65, red: 0.2, green: 0.2, blue: 0.2);

    return Scaffold(
      extendBody: true,
      body: ConstrainedContent(child: child),
      bottomNavigationBar: GlassBottomBar(
        selectedIndex: currentIndex,
        onTabSelected: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/nodes');
            case 2: context.go('/search');
            case 3: context.go('/profile');
          }
        },
        tabWidth: null,
        barHeight: 68,
        barBorderRadius: 40,
        horizontalPadding: 20,
        verticalPadding: 12,
        enableBlend: true,
        blendAmount: 12,
        showIndicator: true,
        indicatorExpansion: 10,
        magnification: 1.1,
        innerBlur: 1.2,
        maskingQuality: MaskingQuality.high,
        interactionBehavior: GlassInteractionBehavior.full,
        pressScale: 1.03,
        settings: LiquidGlassSettings(
          thickness: 32,
          blur: 8,
          refractiveIndex: 1.59,
          chromaticAberration: 0.22,
          lightIntensity: 0.75,
          saturation: 0.8,
          ambientStrength: 0.8,
          lightAngle: 2.356,
          glassColor: glassColor,
        ),
        indicatorSettings: const LiquidGlassSettings(
          glassColor: Color.from(alpha: 0.25, red: 1, green: 1, blue: 1),
          saturation: 1.4,
          refractiveIndex: 1.25,
          thickness: 22,
          lightIntensity: 1.8,
          chromaticAberration: 0.35,
          blur: 1,
          lightAngle: 2.356,
        ),
        selectedIconColor: Colors.white,
        unselectedIconColor: unselectedColor,
        iconSize: 22,
        labelFontSize: 11,
        glowOpacity: 0.55,
        glowBlurRadius: 28,
        glowSpreadRadius: 6,
        tabs: const [
          GlassBottomBarTab(
            label: '首页',
            icon: Icon(Icons.home_outlined, size: 22),
            activeIcon: Icon(Icons.home, size: 24),
          ),
          GlassBottomBarTab(
            label: '节点',
            icon: Icon(Icons.account_tree_outlined, size: 22),
            activeIcon: Icon(Icons.account_tree, size: 24),
          ),
          GlassBottomBarTab(
            label: '搜索',
            icon: Icon(Icons.search_outlined, size: 22),
            activeIcon: Icon(Icons.search, size: 24),
          ),
          GlassBottomBarTab(
            label: '账号',
            icon: Icon(Icons.person_outline, size: 22),
            activeIcon: Icon(Icons.person, size: 24),
          ),
        ],
      ),
    );
  }
}
