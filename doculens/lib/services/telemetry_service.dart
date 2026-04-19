import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/rendering.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  bool get isEnabled => _enabled;

  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logOcrStarted() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'ocr_started');
  }

Future<void> logOcrSuccess({
  required bool namDetected,
  required bool dobDetected,
  required bool genderDetected,
}) async {
  if (!_enabled) return;
  await _analytics.logEvent(
    name: 'ocr_success',
    parameters: {
      'name_detected': namDetected ? 'true' : 'false',
      'dob_detected': dobDetected ? 'true' : 'false',
      'gender_detected': genderDetected ? 'true' : 'false',
    },
  );
}

  Future<void> logOcrFailed() async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'ocr_failed');
  }

  Future<void> logFieldEdited(String fieldName) async {
    if (!_enabled) return;
    await _analytics.logEvent(
      name: 'field_edited',
      parameters: {'field_name': fieldName},
    );
  }

Future<void> logTelemetryToggled(bool enabled) async {
  await _analytics.logEvent(
    name: 'telemetry_toggled',
    parameters: {'enabled': enabled ? 'true' : 'false'},
  );
}
}

