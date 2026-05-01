import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Initialized Successfully");
  } catch (e, st) {
    print("❌ Firebase initialization failed: $e");
    print(st);
  }
  runApp(const ProviderScope(child: GapWiseApp()));
}

class GapWiseApp extends ConsumerWidget {
  const GapWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GapWise - AI Resume Analyzer',
      debugShowCheckedModeBanner: false,
      theme: GapWiseTheme.darkTheme,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const DashboardScreen();
        return const LoginScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
    );
  }
}

