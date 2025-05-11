import 'package:flutter/material.dart';
import '../services/ml_service.dart';
import 'dart:async';

class AthleteDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AthleteDashboardScreen({super.key, required this.userData});

  @override
  State<AthleteDashboardScreen> createState() => _AthleteDashboardScreenState();
}

class _AthleteDashboardScreenState extends State<AthleteDashboardScreen> {
  final MLService _mlService = MLService();
  bool _isLoadingModel = false;
  String _modelStatus = 'Not loaded';
  Map<String, dynamic>? _predictionResults;
  StreamSubscription? _predictionSubscription;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _heartRateController = TextEditingController();
  final _ageController = TextEditingController();
  final _restingBPController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _fastingBSController = TextEditingController();
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    _loadModelAndStartPredictions();
    // Pre-fill with user data if available
    if (widget.userData['heartrate'] != null) {
      _heartRateController.text = widget.userData['heartrate'].toString();
    }

    if (widget.userData['age'] != null) {
      _ageController.text = widget.userData['age'].toString();
    }

    if (widget.userData['gender'] != null) {
      _gender = widget.userData['gender'].toString().toLowerCase();
    }
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _ageController.dispose();
    _restingBPController.dispose();
    _cholesterolController.dispose();
    _fastingBSController.dispose();
    _predictionSubscription?.cancel();
    _mlService.dispose();
    super.dispose();
  }

  void _loadModelAndStartPredictions() async {
    setState(() {
      _isLoadingModel = true;
      _modelStatus = 'Initializing...';
    });

    try {
      // First, get the model
      final model = await _mlService.getHeartStatusModel();

      if (model != null) {
        setState(() {
          _modelStatus = 'Model loaded: ${model.size} bytes';
        });

        // Set up real-time predictions based on user data
        _setupRealtimePredictions();
      } else {
        setState(() {
          _isLoadingModel = false;
          _modelStatus = 'Failed to load model';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingModel = false;
        _modelStatus = 'Error: $e';
      });
    }
  }

  void _setupRealtimePredictions() {
    setState(() {
      _modelStatus = 'Monitoring health data...';
    });

    // Start listening to prediction updates
    _predictionSubscription = _mlService
        .setupRealtimePredictions(widget.userData['uid'])
        .listen(
          (predictionResults) {
            setState(() {
              _isLoadingModel = false;
              _predictionResults = predictionResults;
            });
          },
          onError: (error) {
            setState(() {
              _isLoadingModel = false;
              _modelStatus = 'Error monitoring data: $error';
              _predictionResults = {
                'error': 'Failed to monitor health data: $error',
              };
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => SizedBox(),
            ),
            SizedBox(width: 8),
            Text(
              'Athlete Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Profile Icon Button with animated effect
          Hero(
            tag: 'profileAvatar',
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/athlete_profile',
                    arguments: widget.userData,
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 15,
                    child: Text(
                      widget.userData['name']?.substring(0, 1).toUpperCase() ??
                          'A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                () => Navigator.pushReplacementNamed(context, '/welcome'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header gradient section with animation and shadow
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated avatar
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      widget.userData['name']?.substring(0, 1).toUpperCase() ??
                          'A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
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
                      '${widget.userData['name'] ?? 'Athlete'}',
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Monitoring Section - Now this is the main focus
                  _sectionTitle('Health Monitoring'),
                  SizedBox(height: 16),

                  // Health Monitoring Cards - Two per row
                  Row(
                    children: [
                      // Heart Rate Card
                      Expanded(
                        child: _buildHealthCard(
                          context: context,
                          icon: Icons.monitor_heart,
                          iconColor: Color(0xFFE53935),
                          title: 'Heart Rate',
                          value:
                              widget.userData['heartrate'] != null
                                  ? '${widget.userData['heartrate']}'
                                  : 'No data',
                          unit: 'BPM',
                        ),
                      ),
                      SizedBox(width: 12),
                      // Temperature Card
                      Expanded(
                        child: _buildHealthCard(
                          context: context,
                          icon: Icons.thermostat,
                          iconColor: Color(0xFFFF9800),
                          title: 'Temperature',
                          value:
                              widget.userData['temp'] != null
                                  ? '${widget.userData['temp']}'
                                  : 'No data',
                          unit: '°C',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // ML Model Section
                  _sectionTitle('Health Status Monitor'),
                  SizedBox(height: 16),

                  // ML Model Status Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.model_training,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Health Monitor',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isLoadingModel)
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Status: $_modelStatus',
                            style: TextStyle(
                              color:
                                  _modelStatus.contains('Error') ||
                                          _modelStatus.contains('Failed')
                                      ? Colors.red
                                      : _modelStatus.contains('Model loaded') ||
                                          _modelStatus.contains('Monitoring')
                                      ? Colors.green
                                      : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Prediction Results
                  if (_predictionResults != null) ...[
                    SizedBox(height: 24),
                    _sectionTitle('Health Assessment'),
                    SizedBox(height: 16),

                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color:
                          _predictionResults!.containsKey('error')
                              ? Colors.red.shade50
                              : _predictionResults!['status'] == 'normal'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _predictionResults!.containsKey('error')
                                      ? Icons.error
                                      : _predictionResults!['status'] ==
                                          'normal'
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color:
                                      _predictionResults!.containsKey('error')
                                          ? Colors.red
                                          : _predictionResults!['status'] ==
                                              'normal'
                                          ? Colors.green
                                          : Colors.orange,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _predictionResults!.containsKey('error')
                                        ? 'Error'
                                        : _predictionResults!['status'] ==
                                            'normal'
                                        ? 'Heart Status: Normal'
                                        : 'Heart Status: Abnormal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _predictionResults!.containsKey(
                                                'error',
                                              )
                                              ? Colors.red
                                              : _predictionResults!['status'] ==
                                                  'normal'
                                              ? Colors.green.shade700
                                              : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            if (_predictionResults!.containsKey('error'))
                              Text(
                                _predictionResults!['error'],
                                style: TextStyle(color: Colors.red.shade800),
                              )
                            else ...[
                              _buildResultRow(
                                label: 'Confidence',
                                value:
                                    '${(_predictionResults!['confidence'] * 100).toStringAsFixed(2)}%',
                              ),
                              _buildResultRow(
                                label: 'Risk Factors',
                                value: '${_predictionResults!['risk_factors']}',
                              ),
                              if (_predictionResults!.containsKey('heart_rate'))
                                _buildResultRow(
                                  label: 'Heart Rate',
                                  value:
                                      '${_predictionResults!['heart_rate']} BPM',
                                ),
                              if (_predictionResults!.containsKey(
                                'temperature',
                              ))
                                _buildResultRow(
                                  label: 'Temperature',
                                  value:
                                      '${_predictionResults!['temperature']} °C',
                                ),
                              SizedBox(height: 8),
                              Text(
                                _predictionResults!['status'] == 'normal'
                                    ? 'Your heart health appears to be normal based on the sensor data.'
                                    : 'Your heart health shows signs that might require attention. Please consult with your healthcare provider.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color:
                                      _predictionResults!['status'] == 'normal'
                                          ? Colors.green.shade800
                                          : Colors.orange.shade900,
                                ),
                              ),

                              // Last updated timestamp
                              if (_predictionResults!.containsKey('time'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    'Last updated: ${_formatTimestamp(_predictionResults!['time'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 16),

                  // Info card about data
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Health data is collected in real-time from your sensors. The AI model provides automatic assessment based on your heart rate, temperature, age, and gender.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format timestamp to readable date/time
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Widget _buildResultRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHealthCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
  }) {
    final bool hasData = value != 'No data';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              hasData ? value : 'No data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: hasData ? Colors.black87 : Colors.grey,
              ),
            ),
            Text(
              hasData ? unit : '',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
