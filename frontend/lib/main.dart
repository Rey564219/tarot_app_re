import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_session.dart';
import 'ads/ad_manager.dart';
import 'screens/home_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/history_screen.dart';
import 'screens/warning_screen.dart';
import 'screens/reading_screen.dart';
import 'screens/product_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.instance.initialize();
  runApp(const TarotApp());
}

class TarotApp extends StatefulWidget {
  const TarotApp({super.key});

  @override
  State<TarotApp> createState() => _TarotAppState();
}

class _TarotAppState extends State<TarotApp> {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0E1F2E),
        secondary: Color(0xFFD6A35E),
        surface: Color(0xFFF7F2EA),
        onSurface: Color(0xFF1B1B1B),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F2EA),
      textTheme: GoogleFonts.cormorantGaramondTextTheme().copyWith(
        titleLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.sourceSans3(fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.sourceSans3(),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Tarot App',
      theme: theme,
      routes: {
        '/': (_) => const AppBootstrap(),
        '/home': (_) => const MainShell(initialIndex: 0),
        '/fortune': (_) => const MainShell(initialIndex: 1),
        '/shop': (_) => const MainShell(initialIndex: 2),
        '/mypage': (_) => const MainShell(initialIndex: 3),
        '/history': (_) => const MainShell(initialIndex: 4),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/warning/')) {
          final key = name.replaceFirst('/warning/', '');
          return MaterialPageRoute(builder: (_) => WarningScreen(fortuneTypeKey: key));
        }
        if (name.startsWith('/reading/')) {
          final id = name.replaceFirst('/reading/', '');
          return MaterialPageRoute(builder: (_) => ReadingScreen(readingId: id));
        }
        if (name.startsWith('/product/')) {
          final key = name.replaceFirst('/product/', '');
          return MaterialPageRoute(builder: (_) => ProductScreen(fortuneTypeKey: key));
        }
        return null;
      },
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AppSession.instance.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return ErrorScreen(error: snapshot.error.toString());
        }
        return const MainShell(initialIndex: 0);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E1F2E), Color(0xFF2C3E50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tarot Atlas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Color(0xFFD6A35E)),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('起動に失敗しました: $error'),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      HomeScreen(),
      FortuneScreen(),
      ShopScreen(),
      MyPageScreen(),
      HistoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (idx) => setState(() => _index = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Fortune'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'My Page'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
