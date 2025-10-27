import 'package:locally/auth_gate.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/home/presentation/pages/home_page.dart';

class AppRoutes {
  static const String authGate = '/';
  static const String authPage = '/auth';
  static const String homePage = '/home';
  
  static final routes = {
    AppRoutes.authGate: (context) => const AuthGate(),
    AppRoutes.authPage: (context) => const AuthPage(),
    AppRoutes.homePage: (context) => const HomePage(),
  };
}
