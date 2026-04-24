import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:doculens/screens/scanner_screen.dart';
import 'package:doculens/screens/settings_screen.dart';
import 'package:doculens/services/database_service.dart';
import 'package:doculens/models/document_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<DocumentRecord> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _db.getAllDocuments();
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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

              // --- Hero Action Card ---
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScannerScreen()),
                  );
                  _loadDocuments(); // refresh list after returning from scanner
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

              // --- Recent Documents Section ---
              Text(
                'Recent Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fade(delay: 500.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No documents yet',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _documents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildRecentDocCard(context, _documents[index])
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

  Widget _buildRecentDocCard(BuildContext context, DocumentRecord doc) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final date = doc.createdAt;
    String dateLabel;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      dateLabel = 'Today, $hour:$min';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = '${date.day}/${date.month}/${date.year}';
    }

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
            child: Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}