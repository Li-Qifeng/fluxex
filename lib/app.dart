import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'providers/notification_provider.dart';
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
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/nodes',
          builder: (context, state) => const NodesScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/bookmarks',
      pageBuilder: (context, state) => _slidePage(const BookmarksScreen(), state),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reply/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return _slidePage(ReplyScreen(topicId: id), state);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      pageBuilder: (context, state) => _slidePage(const LoginWebViewScreen(), state),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/notifications',
      pageBuilder: (context, state) => _slidePage(const NotificationsScreen(), state),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/topic/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return _slidePage(TopicDetailScreen(topicId: id), state);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/member/:username',
      pageBuilder: (context, state) {
        final username = state.pathParameters['username']!;
        return _slidePage(MemberDetailScreen(username: username), state);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/node/:name',
      pageBuilder: (context, state) {
        final name = state.pathParameters['name']!;
        return _slidePage(NodeDetailScreen(nodeName: name), state);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/create-topic',
      pageBuilder: (context, state) => _slidePage(const CreateTopicScreen(), state),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/followed-nodes',
      pageBuilder: (context, state) => _slidePage(const FollowedNodesScreen(), state),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      pageBuilder: (context, state) => _slidePage(const SettingsScreen(), state),
    ),
  ],
);

CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

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
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
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
              child: child!,
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
    final unreadCount = ref.watch(unreadCountProvider);
    int currentIndex = 0;
    if (location.startsWith('/nodes')) currentIndex = 1;
    if (location.startsWith('/search')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    return Scaffold(
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
        tabs: [
          GlassBottomBarTab(
            label: '首页',
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
          ),
          GlassBottomBarTab(
            label: '节点',
            icon: const Icon(Icons.account_tree_outlined),
            activeIcon: const Icon(Icons.account_tree),
          ),
          GlassBottomBarTab(
            label: '搜索',
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
          ),
          GlassBottomBarTab(
            label: '账号',
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
