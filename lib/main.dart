import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/password_setup_screen.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/deep_link_service.dart';
import 'theme.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://cgthmzpuqvxeiwqtscsy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNndGhtenB1cXZ4ZWl3cXRzY3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU0NTA1ODEsImV4cCI6MjA2MTAyNjU4MX0.UZdzH0XbcTTAXh_6mI2bgTFW0bH2K_1u_y27kFdMM90',
  );
  
  final storageService = await StorageService.init();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(storageService),
      child: const KinDoApp(),
    ),
  );
}

class KinDoApp extends StatefulWidget {
  const KinDoApp({super.key});

  @override
  State<KinDoApp> createState() => _KinDoAppState();
}

class _KinDoAppState extends State<KinDoApp> {
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDeepLinks();
    });
  }

  void _setupDeepLinks() {
    _deepLinkService.handleInitialUri(_handleLink);
    _deepLinkService.handleIncomingLinks(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (kIsWeb) {
      // For web, handle the URL path and query parameters
      // Remove the leading '#' if present
      final path = uri.fragment.isNotEmpty 
          ? uri.fragment 
          : uri.path.replaceFirst('/', '');
          
      if (path.startsWith('password-setup')) {
        final code = uri.queryParameters['code'];
        if (code != null) {
          navigatorKey.currentState?.pushReplacementNamed(
            '/password-setup',
            arguments: {'code': code},
          );
        }
      }
    } else {
      // For native platforms, handle the custom scheme
      if (uri.host == 'password-setup') {
        final code = uri.queryParameters['code'];
        if (code != null) {
          navigatorKey.currentState?.pushReplacementNamed(
            '/password-setup',
            arguments: {'code': code},
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'KinDo',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/password-setup': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic> && args['code'] != null) {
            return PasswordSetupScreen(token: args['code']);
          }
          return const LoginScreen();
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check for invitation flow
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final metadata = session.user.userMetadata;
          if (metadata != null && metadata['type'] == 'invitation') {
            return PasswordSetupScreen(invitationData: metadata);
          }
        }
        
        return appState.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Navigate to home screen after delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.family_restroom_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'KinDo',
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Family Task Management',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}