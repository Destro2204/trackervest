import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'athlete_detail_screen.dart';

class CoachDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CoachDashboardScreen({super.key, required this.userData});

  @override
  _CoachDashboardScreenState createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _athletes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final athletes = await _firebaseService.getAllAthletes();

      setState(() {
        _athletes = athletes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load athletes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Coach Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                () => Navigator.pushReplacementNamed(context, '/welcome'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header gradient section
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    widget.userData['name']?.substring(0, 1).toUpperCase() ??
                        'C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Coach ${widget.userData['name'] ?? ''}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dashboard content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAthletes,
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAthletes,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _athletes.isEmpty
                      ? _buildEmptyState()
                      : _buildAthletesList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'No Athletes Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Athletes will appear here when they register',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAthletesList() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Athletes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_athletes.length} Athletes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Athletes list
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _athletes.length,
            itemBuilder: (context, index) {
              final athlete = _athletes[index];
              return _buildAthleteCard(athlete);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteCard(Map<String, dynamic> athlete) {
    // Health status indicator - Green for normal, Orange for caution, Red for alert
    final hasHeartRate = athlete['heartrate'] != null;
    final hasTemp = athlete['temp'] != null;

    // Define status indicators
    String healthStatus = 'No Data';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.question_mark;

    if (hasHeartRate || hasTemp) {
      // Simple example logic - in real app would be more sophisticated
      final heartRate = athlete['heartrate'] ?? 0;
      final temp = athlete['temp'] ?? 0;

      if ((heartRate > 100 || heartRate < 50) || (temp > 38 || temp < 35)) {
        healthStatus = 'Alert';
        statusColor = Colors.red;
        statusIcon = Icons.warning_amber;
      } else if ((heartRate > 90 || heartRate < 60) ||
          (temp > 37.5 || temp < 36)) {
        healthStatus = 'Caution';
        statusColor = Colors.orange;
        statusIcon = Icons.info;
      } else {
        healthStatus = 'Normal';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      }
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AthleteDetailScreen(athleteData: athlete),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.2),
                child: Text(
                  athlete['name']?.substring(0, 1).toUpperCase() ?? 'A',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete['name'] ?? 'Unknown Athlete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      athlete['email'] ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Health status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      healthStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
