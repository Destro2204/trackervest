import 'package:flutter/material.dart';
import 'athlete_dashboard_screen.dart';
import 'coach_dashboard_screen.dart';
import 'package:trackervest/services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firebaseService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading...')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle any errors - but with our implementation, we always have data
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading dashboard: ${snapshot.error}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        () =>
                            Navigator.pushReplacementNamed(context, '/welcome'),
                    child: Text('Return to Welcome Screen'),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!;
        final String role = userData['role'] ?? 'athlete';

        if (role == 'coach') {
          return CoachDashboardScreen(userData: userData);
        } else {
          return AthleteDashboardScreen(userData: userData);
        }
      },
    );
  }
}
