import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'setup_profile_personal_screen.dart';
import 'setup_profile_vehicle_screen.dart';
import 'setup_profile_documents_screen.dart';
import 'sos_emergency_screen.dart';
import 'trip_history_screen.dart';
import 'journey_planner_screen.dart'; // Import the JourneyPlannerScreen

void main() {
  runApp(const DriverPortalApp());
}

class DriverPortalApp extends StatelessWidget {
  const DriverPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriverPortal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/setup_profile_personal': (context) => const SetupProfilePersonalScreen(),
        '/setup_profile_vehicle': (context) => const SetupProfileVehicleScreen(),
        '/setup_profile_documents': (context) => const SetupProfileDocumentsScreen(),
        '/sos_emergency': (context) => const SosEmergencyScreen(),
        '/trip_history': (context) => const TripHistoryScreen(),
        '/journey_planner': (context) => const JourneyPlannerScreen(), // Add this route
      },
    );
  }
}