import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  void _toggleTelemetry(bool value) {
    setState(() {
      _telemetryEnabled = value;
    });
    _telemetry.setEnabled(value);
    _telemetry.logTelemetryToggled(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          // --- Section Header ---
          Text(
            'PRIVACY & DATA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ).animate().fade(delay: 100.ms).slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 16),

          // --- Telemetry Control Card ---
          _buildSettingsCard(
            context: context,
            delayMs: 200,
            isGlowing: _telemetryEnabled, // Glows when active
            child: Row(
              children: [
                _buildIconBox(context, Icons.analytics_outlined, _telemetryEnabled),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Analytics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Help us improve by sharing usage data',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _telemetryEnabled,
                  activeColor: theme.colorScheme.primary,
                  activeTrackColor: theme.colorScheme.primary.withOpacity(0.3),
                  inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.4),
                  inactiveTrackColor: theme.colorScheme.surfaceDim,
                  onChanged: _toggleTelemetry,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- Status Indicator Card ---
          _buildSettingsCard(
            context: context,
            delayMs: 300,
            child: Row(
              children: [
                _buildIconBox(context, Icons.cell_tower_rounded, _telemetryEnabled),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Telemetry Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildStatusBadge(context, _telemetryEnabled),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- Section Header ---
          Text(
            'SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ).animate().fade(delay: 400.ms).slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 16),

          // --- App Version Card ---
          _buildSettingsCard(
            context: context,
            delayMs: 500,
            child: Row(
              children: [
                _buildIconBox(context, Icons.info_outline_rounded, false),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'App Version',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '1.0.0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', // Gives it a techy feel
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSettingsCard({
    required BuildContext context,
    required Widget child,
    required int delayMs,
    bool isGlowing = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGlowing 
              ? theme.colorScheme.primary.withOpacity(0.3) 
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: isGlowing ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ] : [],
      ),
      child: child,
    ).animate().fade(delay: delayMs.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildIconBox(BuildContext context, IconData icon, bool isActive) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444); // Emerald or Red
    final text = isActive ? 'Active' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
              ],
            ),
          ).animate(onPlay: (c) => isActive ? c.repeat(reverse: true) : c.stop())
           .fade(begin: 0.4, end: 1.0, duration: 1.seconds),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}