import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../core/services/health_service.dart';

enum HealthState { empty, loading, loaded, success, error }

class HealthProvider with ChangeNotifier {
  final HealthService _healthService;
  HealthProvider(this._healthService);

  HealthState state = HealthState.loading ;
  String errMessage = '';
  int? steps = 0;

  /// to store HealthDataPoint
  // List<HealthDataPoint> healthData = [];
  // var healthPoint = <HealthDataPoint>[];
  List<HealthDataPoint> _healthDataList = [];

  /// Fetch steps points from the health service and show them in the app
  Future<void> fetchStepsData() async {

    // _handleLoading();
    try {
      steps = await _healthService.fetchStepData();

      _handleLoaded();
      // notifyListeners();
      // debugPrint(_steps.toString());
      // return _steps;
    } catch (e) {
      debugPrint('Error at HealthProvider Provider -> fetchData: $e');
      _handleError(e);
    }
    // return 0;
  }

  /// Fetch data points from the health service and show them in the app.
  Future fetchData() async {
    // _handleLoading();
    try {
      List<HealthDataPoint> healthData = await _healthService.fetchHealthData();
      _healthDataList.addAll((healthData.length < 100)
          ? healthData
          : healthData.sublist(0, 100));

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      // // print the results
      // for (var x in _healthDataList) {
      //   debugPrint(x.toString());
      // }

      // _handleLoaded();
      // notifyListeners();
      return _healthDataList;
    } catch (e) {
      debugPrint('Error at HealthProvider Provider -> fetchData: $e');
      _handleError(e);
    }
  }

  void _handleEmpty() {
    state = HealthState.empty;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoading() {
    state = HealthState.loading;
    errMessage = '';
    notifyListeners();
  }

  void _handleLoaded() {
    state = HealthState.loaded;
    errMessage = '';
    notifyListeners();
  }

  void _handleSuccess() {
    state = HealthState.success;
    errMessage = '';
    notifyListeners();
  }

  void _handleError(e) {
    state = HealthState.error;
    errMessage = e.toString();
    notifyListeners();
  }
}

