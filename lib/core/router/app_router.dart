import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/logistician/home_screen.dart';
import '../../screens/driver/driver_dashboard_screen.dart';
import '../../screens/cargo_details_screen.dart';
import '../../screens/chat_screen.dart';
import '../../screens/logistician/add_cargo_screen.dart';

class AppRouter {
  AppRouter._();

  static void toAuth(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static void toHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  static void toDriverDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
      (_) => false,
    );
  }

  static void toCargoDetails(BuildContext context, String cargoId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CargoDetailsScreen(cargoId: cargoId)),
    );
  }

  static Future<void> toAddCargo(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCargoScreen()),
    );
  }

  static void toChat(BuildContext context, String cargoId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(cargoId: cargoId)),
    );
  }
}
