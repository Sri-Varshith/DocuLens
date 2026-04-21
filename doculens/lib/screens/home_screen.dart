import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Added for fluid motion
import 'package:doculens/screens/scanner_screen.dart';
import 'package:doculens/screens/settings_screen.dart';
// import 'your_path/app_colors.dart'; // Ensure your AppColors is imported

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming AppTheme is applied in main.dart, but we'll use Theme.of for safety
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // --- Header Section ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DocuLens',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fade(duration: 400.ms).slideX(begin: -0.2, end: 0),
                      Text(
                        'Ready to digitize?',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ).animate().fade(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    iconSize: 28,
                  ).animate().scale(delay: 200.ms),
                ],
              ),
              const SizedBox(height: 40),

              // --- Hero Action Card (The "Crazy" Aesthetic part) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScannerScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      // The Neon Glow Effect
                      BoxShadow(
                        color: primaryColor.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.document_scanner_rounded,
                          size: 64,
                          color: primaryColor,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                      
                      const SizedBox(height: 24),
                      Text(
                        'New Scan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Extract Name, DOB, and Gender instantly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
              ),

              const SizedBox(height: 48),

              // --- Recent Scans Section (UI Teaser for Future Flow) ---
              Text(
                'Recent Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fade(delay: 500.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 16),
              
              // Placeholder List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: 3, // Mock data count
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    // Staggered animation for list items
                    return _buildRecentDocCard(context, index)
                        .animate()
                        .fade(delay: (600 + (100 * index)).ms)
                        .slideY(begin: 0.2, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Widget for Recent Documents ---
  Widget _buildRecentDocCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    
    // Mock data just to make the UI look populated
    final mockNames = ['Rahul Sharma', 'Ayesha Khan', 'John Doe'];
    final mockDates = ['Today, 10:42 AM', 'Yesterday, 3:15 PM', 'Oct 12, 9:00 AM'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.badge_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mockNames[index],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mockDates[index],
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}