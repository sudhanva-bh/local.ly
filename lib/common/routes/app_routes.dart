import 'package:locally/common/gates/auth_gate.dart';
import 'package:locally/common/gates/setup_gate.dart';
import 'package:locally/features/auth/pages/auth_page.dart';
import 'package:locally/features/retail_seller/home/presentation/pages/retail_home_page.dart';
import 'package:locally/features/setup/setup_page.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/wholesale_nav_page.dart';
import 'package:locally/common/gates/seller_type_gate.dart';

class AppRoutes {
  static const String authGate = '/';
  static const String setupGate = '/setupGate';
  static const String sellerTypeGate = '/sellerGate';
  static const String authPage = '/auth';
  static const String setupPage = '/setup';
  static const String wholesaleNavPage = 'wholesale/nav';
  static const String retailHomePage = 'retail/home';

  static final routes = {
    AppRoutes.authGate: (context) => const AuthGate(),
    AppRoutes.setupGate: (context) => const SetupGate(),
    AppRoutes.sellerTypeGate: (context) => const SellerTypeGate(),
    AppRoutes.authPage: (context) => const AuthPage(),
    AppRoutes.setupPage: (context) => const SetupPage(),
    AppRoutes.wholesaleNavPage: (context) => const WholesaleNavPage(),
    AppRoutes.retailHomePage: (context) => const RetailHomePage(),
  };
}
