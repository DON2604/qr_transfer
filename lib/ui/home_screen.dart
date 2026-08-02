import 'package:flutter/material.dart';

import 'history/history_screen.dart';
import 'receiver/qr_scanner_view.dart';
import 'sender/file_selector_card.dart';
import 'sender/qr_stream_player.dart';
import 'widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SelectedFileInfo? _selectedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark midnight background
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              const Color(0xFF1E1B4B).withValues(alpha: 0.8), // Purple radial glow
              const Color(0xFF0F172A), // Midnight slate base
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // App Header Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AirTransfer QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Optical Air-Gapped File Transfer',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Futuristic Tab Selector Bar
                GlassCard(
                  padding: const EdgeInsets.all(4),
                  borderRadius: 16,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.qr_code_rounded, size: 20),
                        text: 'Send (QR)',
                      ),
                      Tab(
                        icon: Icon(Icons.center_focus_strong_rounded, size: 20),
                        text: 'Receive',
                      ),
                      Tab(
                        icon: Icon(Icons.folder_special_rounded, size: 20),
                        text: 'History',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Contents
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: SENDER
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            FileSelectorCard(
                              onFileSelected: (info) {
                                setState(() {
                                  _selectedFile = info;
                                });
                              },
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 16),
                              QrStreamPlayer(fileInfo: _selectedFile!),
                            ],
                          ],
                        ),
                      ),

                      // Tab 2: RECEIVER
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: QrScannerView(
                          onTransferSuccess: () {
                            // Switch to history tab upon success if desired or keep on success screen
                          },
                        ),
                      ),

                      // Tab 3: HISTORY
                      const HistoryScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
