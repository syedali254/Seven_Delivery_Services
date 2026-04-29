import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );

  runApp(const SevenDeliveryApp());
}

class SevenDeliveryApp extends StatelessWidget {
  const SevenDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seven Delivery Service',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGuard(),
    );
  }
}

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isMobileSimulator = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        
        if (session == null) {
          return const LoginScreen();
        }

        // Only show simulator toggle on WEB. Never on APK/Mobile.
        Widget mainContent = const MainNavigationScreen();

        if (kIsWeb && _isMobileSimulator) {
          mainContent = Center(
            child: Container(
              width: 450,
              height: 850,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.black, width: 12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: const MainNavigationScreen(),
              ),
            ),
          );
        }

        return Scaffold(
          body: mainContent,
          // Floating button ONLY on Web
          floatingActionButton: kIsWeb 
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => _isMobileSimulator = !_isMobileSimulator),
                label: Text(_isMobileSimulator ? 'Exit Simulator' : 'Simulate Pixel 6 Pro'),
                icon: Icon(_isMobileSimulator ? Icons.fullscreen : Icons.phone_android),
                backgroundColor: AppTheme.darkColor,
              )
            : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }
}
