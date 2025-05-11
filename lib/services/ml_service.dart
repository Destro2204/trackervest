import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class MLService {
  // Singleton pattern
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  // Store the model
  FirebaseCustomModel? _model;
  bool _isModelDownloading = false;
  bool _isModelLoaded = false;

  // Stream controller for real-time predictions
  Stream<Map<String, dynamic>>? _predictionsStream;

  // The last known user data
  Map<String, dynamic>? _lastUserData;

  Future<FirebaseCustomModel?> getHeartStatusModel() async {
    // Return the cached model if already downloaded
    if (_model != null) {
      _isModelLoaded = true;
      return _model;
    }

    // If a download is already in progress, wait for it
    if (_isModelDownloading) {
      // Wait until the model is downloaded
      while (_isModelDownloading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _model;
    }

    try {
      _isModelDownloading = true;

      // Default conditions without specifying WiFi requirement
      final conditions = FirebaseModelDownloadConditions();

      print('Starting download of heart-status ML model...');

      // Try to get the model
      _model = await FirebaseModelDownloader.instance.getModel(
        'heart-status',
        FirebaseModelDownloadType.localModel,
        conditions,
      );

      print('✅ ML model downloaded successfully.');
      print('   - Model size: ${_model?.size ?? 0} bytes');
      print('   - Model path: ${_model?.file?.path}');

      _isModelLoaded = true;
      return _model;
    } catch (e) {
      print('❌ Error downloading ML model: $e');
      return null;
    } finally {
      _isModelDownloading = false;
    }
  }

  // Setup real-time prediction stream for a user
  Stream<Map<String, dynamic>> setupRealtimePredictions(String userId) {
    // Load the model first if not loaded
    if (!_isModelLoaded) {
      getHeartStatusModel();
    }

    print('Setting up real-time predictions for user ID: $userId');

    // Create a stream that listens to user data changes by document ID
    final userDataStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
          if (!snapshot.exists) {
            print('❌ User document not found with ID: $userId');
            return {'error': 'User data not found'};
          }

          final userData = snapshot.data() as Map<String, dynamic>;
          _lastUserData = userData;

          print('✅ Found user data with health metrics:');
          if (userData.containsKey('heartrate'))
            print('   - Heart rate: ${userData['heartrate']}');
          if (userData.containsKey('temp'))
            print('   - Temperature: ${userData['temp']}');
          if (userData.containsKey('age'))
            print('   - Age: ${userData['age']}');
          if (userData.containsKey('gender'))
            print('   - Gender: ${userData['gender']}');

          // Check if we have all required fields
          if (!_hasRequiredFields(userData)) {
            return {'error': 'Missing required health data for prediction'};
          }

          // Make prediction using the current data
          return await predictHeartStatus(userData);
        });

    _predictionsStream = userDataStream;
    return userDataStream;
  }

  // Check if the user data has all required fields
  bool _hasRequiredFields(Map<String, dynamic> userData) {
    return userData['heartrate'] != null &&
        userData['temp'] != null &&
        userData['age'] != null &&
        userData['gender'] != null;
  }

  // Method to predict heart status based on collected data
  Future<Map<String, dynamic>> predictHeartStatus([
    Map<String, dynamic>? inputData,
  ]) async {
    try {
      final model = await getHeartStatusModel();

      if (model == null || !_isModelLoaded) {
        return {'error': 'Model not available'};
      }

      // Use provided input data or last known user data
      final data = inputData ?? _lastUserData;

      if (data == null) {
        return {'error': 'No health data available for prediction'};
      }

      // Extract the required features
      final heartRate =
          data['heartrate'] is num
              ? data['heartrate'].toDouble()
              : (data['heartRate'] is num
                  ? data['heartRate'].toDouble()
                  : 70.0);

      final temperature =
          data['temp'] is num
              ? data['temp'].toDouble()
              : (data['temperature'] is num
                  ? data['temperature'].toDouble()
                  : 37.0);

      final age = data['age'] is num ? data['age'].toDouble() : 30.0;

      final gender =
          data['gender'] is String
              ? data['gender'].toString().toLowerCase()
              : 'male';

      // Risk factors counter
      int riskFactors = 0;
      double riskScore = 0.0;

      // Check heart rate based on age
      final bool isHeartRateNormal = _isHeartRateNormal(heartRate, age);
      if (!isHeartRateNormal) {
        riskFactors++;
        riskScore += 0.3;
      }

      // Check temperature
      final bool isTempNormal = temperature >= 36.1 && temperature <= 37.2;
      if (!isTempNormal) {
        riskFactors++;
        riskScore += 0.3;
        // High fever is more concerning
        if (temperature > 38.0) {
          riskScore += 0.2;
        }
      }

      // Age factor
      if (age > 55 && gender == 'male' || age > 65 && gender == 'female') {
        riskFactors++;
        riskScore += 0.1;
      }

      // Calculate final risk
      final bool isNormal = riskFactors < 2 && riskScore < 0.5;

      // Normalize risk score to 0-1 range
      riskScore = riskScore > 1.0 ? 1.0 : riskScore;

      // Calculate confidence (inverse of risk for normal status)
      final double confidence = isNormal ? 1.0 - riskScore : riskScore;

      final result = {
        'status': isNormal ? 'normal' : 'abnormal',
        'confidence': confidence,
        'raw_value': riskScore,
        'risk_factors': riskFactors,
        'time': DateTime.now().millisecondsSinceEpoch,
        'model_path': _model?.file?.path,
        'heart_rate': heartRate,
        'temperature': temperature,
      };

      print('Real-time prediction results: $result');
      return result;
    } catch (e) {
      print('❌ Error making prediction: $e');
      return {
        'error': 'Prediction failed: $e',
        'time': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  bool _isHeartRateNormal(double heartRate, double age) {
    // Age-based normal heart rate ranges
    if (age < 25) {
      return heartRate >= 60 && heartRate <= 100;
    } else if (age < 35) {
      return heartRate >= 60 && heartRate <= 95;
    } else if (age < 45) {
      return heartRate >= 60 && heartRate <= 93;
    } else if (age < 55) {
      return heartRate >= 60 && heartRate <= 90;
    } else if (age < 65) {
      return heartRate >= 55 && heartRate <= 90;
    } else {
      return heartRate >= 50 && heartRate <= 85;
    }
  }

  // Clean up resources
  void dispose() {
    // No streams to close in this implementation
  }
}
