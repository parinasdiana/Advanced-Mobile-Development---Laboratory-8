import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartAlertApp());
}

class SmartAlertApp extends StatelessWidget {
  const SmartAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Deep Blue Agent Theme
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lat = "--";
  String _long = "--";
  bool _isLoading = false;
  final FlutterLocalNotificationsPlugin _notifs =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initMobileNotifs();
  }

  Future<void> _initMobileNotifs() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifs.initialize(
      settings: const InitializationSettings(android: android),
    );
  }

  Future<void> _sendAlert(String title, String body) async {
    if (kIsWeb) {
      // Web Fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title: $body"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Mobile Notification
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'field_agent_channel',
            'Mission Updates',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // FIXED: Added explicit names (id:, title:, etc.) for all arguments
      await _notifs.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: platformDetails,
      );
    }
  }

  Future<void> _handleLocation() async {
    setState(() => _isLoading = true);

    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading
      setState(() {
        _lat = "14.5995";
        _long = "120.9842";
        _isLoading = false;
      });
      _sendAlert("Web Location Update", "Coordinates updated via Browser");
      return;
    }

    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() {
          _lat = pos.latitude.toStringAsFixed(4);
          _long = pos.longitude.toStringAsFixed(4);
          _isLoading = false;
        });
        _sendAlert("Location Locked", "Agent Position: $_lat, $_long");
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "AGENT TRACKER",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            const Text(
              "MISSION STATUS: ACTIVE",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // Location Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 40,
                      color: Color(0xFF0D47A1),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _coordColumn("LATITUDE", _lat),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                              ),
                              _coordColumn("LONGITUDE", _long),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.my_location),
              label: const Text(
                "GET MY LOCATION",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  _sendAlert("HQ UPDATE", "Status report received. Stand by."),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF0D47A1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text("SEND ALERT TO HQ"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
