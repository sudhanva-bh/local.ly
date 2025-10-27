import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/auth_gate.dart';
import 'package:locally/common/providers/theme_provider.dart';
import 'package:locally/common/routes/app_routes.dart';
import 'package:locally/common/theme/app_theme.dart';
import 'package:locally/firebase_options.dart';
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

class MyApp extends ConsumerWidget  {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Locally',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.authGate,
    );
  }
}
