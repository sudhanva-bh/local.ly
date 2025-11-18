// Import your splash screen at the top

import 'package:locally/common/gates/app_gate.dart';
import 'package:locally/common/utilities/splash_screen.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';

class AppRoutes {
  // Add a route for the splash screen
  static const String splash = '/'; // <-- CHANGED (This is the new initial route)
  
  // Give AppGate its own route name
  static const String appGate = '/app-gate'; // <-- CHANGED (Was '/')
  
  static const String authPage = '/auth';
  static const String setupPage = '/setup';
  static const String wholesaleNavPage = 'wholesale/nav';
  static const String retailHomePage = 'retail/home';

  static final routes = {
    // Add the splash screen to the map
    AppRoutes.splash: (context) => const GifSplash(), // <-- CHANGED (Add this line)
    
    AppRoutes.appGate: (context) => const AppGate(),
    AppRoutes.authPage: (context) => const AuthPage(),
    AppRoutes.setupPage: (context) => const SetupPage(),
    AppRoutes.wholesaleNavPage: (context) => const WholesaleNavPage(),
  };
}
