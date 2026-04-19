import 'package:flutter/material.dart';
import 'package:doculens/services/telemetry_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TelemetryService _telemetry = TelemetryService();
  bool _telemetryEnabled = true;

  @override
  void initState() {
    super.initState();
    _telemetryEnabled = _telemetry.isEnabled;
    _telemetry.logScreenView('settings_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Telemetry'),
            value: _telemetryEnabled,
            onChanged: (value) {
              setState(() {
                _telemetryEnabled = value;
              });
              _telemetry.setEnabled(value);
              _telemetry.logTelemetryToggled(value);
            },
          ),
          ListTile(
            title: const Text('Telemetry Status'),
            trailing: Text(
              _telemetryEnabled ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _telemetryEnabled ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const ListTile(
            title: Text('App Version'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}