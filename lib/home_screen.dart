import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:DHB/screens/dashboard_screen.dart';
import 'package:DHB/screens/nearby_facilities_screen.dart';
import 'package:DHB/screens/medications_screen.dart';
import 'package:DHB/screens/appointments_screen.dart';
import 'package:DHB/screens/upload_document.dart';
import 'package:DHB/screens/health_qr_screen.dart';
import 'package:DHB/screens/monitor_analytics_screen.dart';
import 'package:DHB/ai/ai_agent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final AIAgent _aiAgent;
  String _agentFeedback = '';
  bool _isAgentActive = false;
  bool _isAgentInitialized = false;
  Timer? _feedbackTimer;

  final List<String> _drawerItems = ['Dashboard', 'Nearby Facility', 'Logout'];
  final List<Widget> _tabs = [
    const DashboardScreen(),
    const MedicationScreen(),
    const AppointementsScreen(),
    const UploadDocumentScreen(),
    const NearbyFacilitiesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAgent();
  }

  Future<void> _initializeAgent() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception('Microphone permission denied');
      }

      _aiAgent = AIAgent(
        onNavigate: _handleNavigation,
        onFeedback: _handleFeedback,
        onLogout: () => _onDrawerItemTapped('Logout'),
        onShowAnalytics: _showAnalytics,
        onShowHealthQR: _showHealthQR,
      );

      await _aiAgent.initialize();

      if (mounted) {
        setState(() => _isAgentInitialized = true);

        final prefs = await SharedPreferences.getInstance();
        final isFirstLaunch = prefs.getBool('first_launch') ?? true;

        if (isFirstLaunch) {
          await prefs.setBool('first_launch', false);
          _toggleAgent(); // Activate agent on first launch
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Assistant initialization failed: $e')),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  void _handleFeedback(String feedback) {
    _feedbackTimer?.cancel();
    setState(() => _agentFeedback = feedback);

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _agentFeedback = '');
      }
    });
  }

  void _showAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonitorAnalyticsScreen()),
    );
  }

  void _showHealthQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthQrScreen(qrData: '')),
    );
  }

  Future<void> _toggleAgent() async {
    if (!_isAgentInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistant still initializing')));
      return;
    }

    if (!await Permission.microphone.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone access is required')));
      return;
    }

    setState(() => _isAgentActive = !_isAgentActive);
    _aiAgent.setAgentActive(_isAgentActive);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onDrawerItemTapped(String title) {
    switch (title) {
      case 'Dashboard':
        _onTabSelected(0);
        break;
      case 'Nearby Facility':
        _onTabSelected(4);
        break;
      case 'Logout':
        Navigator.popUntil(context, (r) => r.isFirst);
        break;
    }
    Navigator.pop(context);
  }

  void _openHealthQRScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthQrScreen(qrData: '')),
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _aiAgent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Health"),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isAgentActive
                  ? const Icon(Icons.mic, key: ValueKey('mic-on'), color: Colors.red)
                  : const Icon(Icons.mic_off, key: ValueKey('mic-off')),
            ),
            onPressed: _toggleAgent,
            tooltip: 'Voice Assistant',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Digital Health Bharat", 
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 8),
                  Text("AI-Powered Health Assistant", 
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ..._drawerItems.map((item) => ListTile(
              title: Text(item),
              onTap: () => _onDrawerItemTapped(item),
            )),
          ],
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _tabs,
          ),
          if (_agentFeedback.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _agentFeedback,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: "Meds",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "Documents",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: "Nearby",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.medication, color: Colors.deepPurple),
                title: const Text("Add Medication"),
                onTap: () {
                  Navigator.pop(context);
                  _onTabSelected(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.deepPurple),
                title: const Text("Generate Health QR"),
                onTap: () {
                  Navigator.pop(context);
                  _openHealthQRScreen();
                },
              ),
              ListTile(
                leading: Icon(
                  _isAgentActive ? Icons.mic_off : Icons.mic,
                  color: Colors.deepPurple,
                ),
                title: Text(_isAgentActive ? "Turn Off Assistant" : "Turn On Assistant"),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAgent();
                },
              ),
            ],
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

extension on AIAgent {
  void setAgentActive(bool isAgentActive) {}
}