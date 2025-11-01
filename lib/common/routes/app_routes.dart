import 'package:locally/common/gates/app_gate.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/retail_seller/home/presentation/pages/retail_home_page.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';

class AppRoutes {
  static const String appGate = '/';
  static const String authPage = '/auth';
  static const String setupPage = '/setup';
  static const String wholesaleNavPage = 'wholesale/nav';
  static const String retailHomePage = 'retail/home';

  static final routes = {
    AppRoutes.appGate: (context) => const AppGate(),
    AppRoutes.authPage: (context) => const AuthPage(),
    AppRoutes.setupPage: (context) => const SetupPage(),
    AppRoutes.wholesaleNavPage: (context) => const WholesaleNavPage(),
    AppRoutes.retailHomePage: (context) => const RetailHomePage(),
  };
}
