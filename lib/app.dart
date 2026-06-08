import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/notification_provider.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class V2exApp extends StatelessWidget {
  const V2exApp({super.key});

  ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      cardTheme: CardTheme(
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
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
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
          builder: (context, state) => const BookmarksScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/reply/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ReplyScreen(topicId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/login',
          builder: (context, state) => const LoginWebViewScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/topic/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TopicDetailScreen(topicId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/member/:username',
          builder: (context, state) {
            final username = state.pathParameters['username']!;
            return MemberDetailScreen(username: username);
          },
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: '/node/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return NodeDetailScreen(nodeName: name);
          },
        ),
      ],
    );

    return ProviderScope(
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
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
            theme: _buildTheme(lightDynamic ?? fallbackLight),
            darkTheme: _buildTheme(darkDynamic ?? fallbackDark),
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
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

    Widget notificationIcon(IconData icon) {
      if (unreadCount <= 0) return Icon(icon);
      return Badge(
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        child: Icon(icon),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/nodes');
          if (index == 2) context.go('/search');
          if (index == 3) context.go('/profile');
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: '节点',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: notificationIcon(Icons.person_outline),
            selectedIcon: notificationIcon(Icons.person),
            label: '账号',
          ),
        ],
      ),
    );
  }
}
