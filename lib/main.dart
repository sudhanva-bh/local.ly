import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/theme/app_theme.dart';
import 'package:locally/features/auth/presentation/auth_page.dart';
import 'package:locally/features/home/presentation/home_page.dart';
import 'package:locally/firebase_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: "https://gkajdgheakgwhesaqqkt.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdrYWpkZ2hlYWtnd2hlc2FxcWt0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3MjEwMjcsImV4cCI6MjA3NjI5NzAyN30.Y5GEG2x5cVWQop5nDSPI3Kwg_uGOrvwAECfc2Ho2V-4",
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Stream of auth changes
    final authStream = supabase.auth.onAuthStateChange
        .map((event) => event.session?.user)
        .startWith(supabase.auth.currentUser);

    return MaterialApp(
      title: 'Locally',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: authStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            final user = snapshot.data;
            return user != null ? const HomePage() : const AuthPage();
          }
        },
      ),
    );
  }
}
