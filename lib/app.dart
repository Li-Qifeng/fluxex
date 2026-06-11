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
          seedColor: const Color(0xFF446CB3),
          brightness: Brightness.light,
        );
        final fallbackDark = ColorScheme.fromSeed(
          seedColor: const Color(0xFF446CB3),
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
                  ambientStrength: 0.1,
                  refractiveIndex: 1.4,
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
        barHeight: 64,
        barBorderRadius: 40,
        horizontalPadding: 16,
        verticalPadding: 10,
        enableBlend: true,
        blendAmount: 16,
        showIndicator: true,
        indicatorExpansion: 6,
        magnification: 1.03,
        innerBlur: 2.0,
        maskingQuality: MaskingQuality.high,
        interactionBehavior: GlassInteractionBehavior.full,
        pressScale: 1.02,
        settings: const LiquidGlassSettings(
          thickness: 32,
          blur: 24,
          refractiveIndex: 1.62,
          chromaticAberration: 0.14,
          lightIntensity: 0.7,
          saturation: 0.9,
          ambientStrength: 0.4,
          lightAngle: 2.5,
          glassColor: Color.from(alpha: 0.10, red: 1, green: 1, blue: 1),
        ),
        indicatorSettings: const LiquidGlassSettings(
          glassColor: Color.from(alpha: 0.45, red: 1, green: 1, blue: 1),
          saturation: 1.6,
          refractiveIndex: 1.35,
          thickness: 24,
          lightIntensity: 2.2,
          chromaticAberration: 0.2,
          blur: 3,
          lightAngle: 2.5,
        ),
        tabs: [
          GlassBottomBarTab(
            label: '首页',
            icon: const Icon(Icons.home_outlined, size: 22),
            activeIcon: const Icon(Icons.home, size: 24),
          ),
          GlassBottomBarTab(
            label: '节点',
            icon: const Icon(Icons.account_tree_outlined, size: 22),
            activeIcon: const Icon(Icons.account_tree, size: 24),
          ),
          GlassBottomBarTab(
            label: '搜索',
            icon: const Icon(Icons.search_outlined, size: 22),
            activeIcon: const Icon(Icons.search, size: 24),
          ),
          GlassBottomBarTab(
            label: '账号',
            icon: const Icon(Icons.person_outline, size: 22),
            activeIcon: const Icon(Icons.person, size: 24),
          ),
        ],
      ),
    );
  }
}
