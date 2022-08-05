import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {

  // create a HealthFactory for use in the app
  HealthFactory health = HealthFactory();

  // HealthService(this.health);

  /// Fetch steps from the health plugin and show them in the app.
  Future<int?> fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool requested = await health.requestAuthorization([HealthDataType.STEPS]);

    if (requested) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now);
      } catch (error) {
        debugPrint("Caught exception in getTotalStepsInInterval: $error");
      }
      steps ??= 0;
      debugPrint('Total number of steps: $steps');
    } else {
      debugPrint("Authorization not granted - error in authorization");
    }

    return steps;
  }

  Future<List<HealthDataPoint>> fetchHealthData() async {

    /// Give a HealthDataType with the given identifier
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      // HealthDataType.STEPS,
      // HealthDataType.WEIGHT,
      // HealthDataType.HEIGHT,
      // HealthDataType.BLOOD_GLUCOSE,
      // Uncomment these 2 lines on iOS - only available on iOS
      // HealthDataType.HIGH_HEART_RATE_EVENT,
      // HealthDataType.WORKOUT,
      // HealthDataType.DISTANCE_WALKING_RUNNING,
      // HealthDataType.AUDIOGRAM

    ];

    /// Give a permissions for the given HealthDataTypes
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ,
      // HealthDataAccess.READ,

    ];

    /// current time
    final now = DateTime.now();

    /// Give a yesterday's time
    final yesterday = now.subtract(const Duration(days: 1));

    /// to store HealthDataPoint
    List<HealthDataPoint> healthData = [];

    /// request google Authorization when the app is opened for the first time
    /// requesting access to the data types before reading them
    /// note that strictly speaking, the [permissions] are not
    /// needed, since we only want READ access.
    bool requested = await health.requestAuthorization(types, permissions: permissions);
    debugPrint('requested: $requested');

    /// If we are trying to read Step Count, Workout, Sleep or other data that requires
    /// the ACTIVITY_RECOGNITION permission, we need to request the permission first.
    /// This requires a special request authorization call.
    /// The location permission is requested for Workouts using the Distance information.
    await Permission.activityRecognition.request();
    await Permission.location.request();

    /// check if the request is successful
    if (requested) {
      try {
        /// fetch the data from the health store
        healthData = await health.getHealthDataFromTypes(yesterday, now, types);

        // // fetch health data from the last 24 hours
        // healthData = await health.getHealthDataFromTypes(
        //     now.subtract(const Duration(days: 1)), now, types);

      } catch (error) {
        debugPrint("Exception in getHealthDataFromTypes: $error");
      }
    } else {
      /// if the request is not successful
      debugPrint("Authorization not granted");
      // throw AuthenticationRequired();
    }
    return healthData;
  }

}