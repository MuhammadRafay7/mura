import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CORE & SERVICES ---
import 'core/constants/colors.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/notification_service.dart';

// --- SHARED WIDGETS ---
import 'shared/widgets/mura_nav_dock.dart';
import 'shared/widgets/force_positive_box.dart';

// --- FEATURES ---
import 'features/identity/passport_screen.dart';
import 'features/contacts/contacts_view.dart';
import 'features/archive/vault_view.dart';
import 'features/auth/login_screen.dart';

void main() async {
  // 1. Initialize Flutter Binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: 'https://smhjhrjxkdftjzsclpbq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtaGpocmp4a2RmdGp6c2NscGJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMDg3MTAsImV4cCI6MjA5MDc4NDcxMH0.3hZyARAq5jPEAPjwMV19pJNYWWFVH57xpP__-LgfLL8',
  );

  // 3. Set UI Style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(const MuraApp());
}

class MuraApp extends StatelessWidget {
  const MuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MuraThemeController(),
      builder: (context, child) {
        final isDark = MuraThemeController().isDarkMode;

        return MaterialApp(
          title: 'MURA',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: MuraColors.background,
            textTheme:
                GoogleFonts.spaceMonoTextTheme(ThemeData.light().textTheme)
                    .apply(
              bodyColor: MuraColors.textPrimary,
              displayColor: MuraColors.textPrimary,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            textTheme:
                GoogleFonts.spaceMonoTextTheme(ThemeData.dark().textTheme)
                    .apply(
              bodyColor: Colors.white.withOpacity(0.9),
              displayColor: Colors.white,
            ),
          ),
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/main': (context) => const MainLayout(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    MuraNotificationService()
        .init()
        .catchError((e) => debugPrint("Notif Error: $e"));

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && !session.isExpired) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Index 0 = ContactsView, Index 1 = VaultView, Index 2 = PassportScreen
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ContactsView(),
    const VaultView(),
    const PassportScreen(),
  ];

  void _handleTabSelection(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MuraThemeController().isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color.fromRGBO(240, 238, 233, 1),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: ForcePositiveBox(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _pages[_currentIndex],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: MuraNavDock(
                  currentIndex: _currentIndex,
                  onTabSelected: _handleTabSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
