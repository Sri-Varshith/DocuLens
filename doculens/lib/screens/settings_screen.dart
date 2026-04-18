import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _telemetryEnabled = true;

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
            },
          ),
          ListTile(
            title: const Text('Telemetry status'),
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
