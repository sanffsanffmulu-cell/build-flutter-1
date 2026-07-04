import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;

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
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('http://fakz.cyberpanel.web.id:3003'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            _handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            _handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
      if (data['type'] == 'stats') {
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConnections = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("⚠️ Session Expired", style: TextStyle(color: cyanLight, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: softWhite.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text("OK", style: TextStyle(color: cyanLight, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = ToolsPage(
            sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 3) _selectedPage = NikCheckerPage();
      else if (index == 4) _selectedPage = ChangePasswordPage(username: username, sessionKey: sessionKey);
      else if (index == 5) _selectedPage = SellerPage(keyToken: sessionKey);
      else if (index == 6) _selectedPage = AdminPage(sessionKey: sessionKey);
    });
  }

  Widget _buildNewsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // News Section
          Container(
            width: double.infinity,
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final item = newsList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cardBlue,
                    boxShadow: [
                      BoxShadow(
                        color: cyanLight.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item['image'] != null && item['image'].toString().isNotEmpty)
                          NewsMedia(url: item['image']),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                                primaryBlue.withOpacity(0.1),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'No Title',
                                style: TextStyle(
                                  color: softWhite,
                                  fontSize: 14,
                                  fontFamily: "Orbitron",
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: cyanLight.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc'] ?? '',
                                style: TextStyle(
                                  color: cyanLight,
                                  fontFamily: "ShareTechMono",
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Account Info Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cyanLight.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, cyanLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, color: softWhite, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "ACCOUNT INFO",
                          style: TextStyle(
                            color: softWhite,
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Info
                  _buildCompactInfoItem(
                    icon: Icons.person,
                    label: "Username",
                    value: username,
                  ),
                  const SizedBox(height: 12),

                  _buildCompactInfoItem(
                    icon: Icons.verified_user,
                    label: "Role",
                    value: role.toUpperCase(),
                    valueColor: _getRoleColor(role),
                  ),
                  const SizedBox(height: 12),

                  _buildCompactInfoItem(
                    icon: Icons.calendar_today,
                    label: "Expired",
                    value: expiredDate,
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactInfoItem(
                          icon: Icons.people,
                          label: "Online",
                          value: "$onlineUsers",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactInfoItem(
                          icon: Icons.link,
                          label: "Connections",
                          value: "$activeConnections",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Manage Bug Sender Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.bug_report, color: softWhite, size: 18),
                      label: Text(
                        "MANAGE BUG SENDER",
                        style: TextStyle(
                          color: softWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: cyanLight.withOpacity(0.5)),
                        ),
                        elevation: 4,
                        shadowColor: cyanLight.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BugSenderPage(
                              sessionKey: sessionKey,
                              username: username,
                              role: role,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ===== BOX TQTO (SEMUA FONT SHARETECHMONO, WARNA BIRU) =====
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: cyanLight,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
              color: cardBlue.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: cyanLight.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // ===== TULISAN TQTO (FONT SHARETECHMONO) =====
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue,
                          cyanLight,
                          tealAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cyanLight.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 5),
                        ),
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(-3, -3),
                        ),
                      ],
                    ),
                    child: Text(
                      "TQTO",
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ShareTechMono',
                        color: softWhite,
                        letterSpacing: 12,
                        shadows: [
                          Shadow(
                            color: primaryDark.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(3, 3),
                          ),
                          Shadow(
                            color: cyanLight.withOpacity(0.8),
                            blurRadius: 20,
                            offset: Offset(-3, -3),
                          ),
                          Shadow(
                            color: tealAccent.withOpacity(0.5),
                            blurRadius: 15,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // ===== JARAK 2 BARIS SETELAH TQTO =====
                const SizedBox(height: 40),

                // ===== TULISAN KREATOR & BEST FRIEND (SEMUA SHARETECHMONO) =====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KREATOR : ZARRNOTDEV
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            child: Text(
                              "KREATOR :",
                              style: TextStyle(
                                color: cyanLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "ZARRNOTDEV",
                              style: TextStyle(
                                color: softWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BEST FRIEND: KaiiOfficial
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            child: Text(
                              "BEST FRIEND:",
                              style: TextStyle(
                                color: cyanLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "KaiiOfficial",
                              style: TextStyle(
                                color: softWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BEST FRIEND: kyyxXxror
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            child: Text(
                              "BEST FRIEND:",
                              style: TextStyle(
                                color: cyanLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "kyyxXxror",
                              style: TextStyle(
                                color: softWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BEST FRIEND: Sayroofficial
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            child: Text(
                              "BEST FRIEND:",
                              style: TextStyle(
                                color: cyanLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Sayroofficial",
                              style: TextStyle(
                                color: softWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ===== JARAK 1 BARIS SEBELUM COPYRIGHT =====
                const SizedBox(height: 20),

                // ===== COPYRIGHT 2026 =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.3), cyanLight.withOpacity(0.3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cyanLight.withOpacity(0.5)),
                  ),
                  child: Text(
                    "© 2026 INFINITY All rights reserved.",
                    style: TextStyle(
                      color: softWhite,
                      fontSize: 14,
                      fontFamily: 'ShareTechMono',
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return royalBlue;
      case "vip":
        return cyanLight;
      case "reseller":
        return Colors.greenAccent;
      case "premium":
        return Colors.orangeAccent;
      default:
        return softWhite;
    }
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cyanLight.withOpacity(0.1)),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            primaryBlue.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: cyanLight.withOpacity(0.3)),
            ),
            child: Icon(icon, color: cyanLight, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: softWhite.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                    shadows: valueColor == softWhite ? [
                      Shadow(
                        color: cyanLight.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ] : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: primaryDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, cyanLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, cyanLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yoshimitsu",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: softWhite,
                          shadows: [
                            Shadow(
                              color: primaryDark.withOpacity(0.5),
                              blurRadius: 5,
                              offset: Offset(1, 1),
                            ),
                          ]
                      )),
                  const SizedBox(height: 12),
                  _buildDrawerInfo("User:", username),
                  _buildDrawerInfo("Role:", role),
                  _buildDrawerInfo("Expired:", expiredDate),
                ],
              ),
            ),
          ),
          if (role == "reseller" || role == "owner")
            _buildDrawerItem(
              icon: Icons.person,
              label: "Seller Page",
              onTap: () {
                Navigator.pop(context);
                _onSidebarTabSelected(5);
              },
            ),
          if (role == "owner")
            _buildDrawerItem(
              icon: Icons.admin_panel_settings,
              label: "Admin Page",
              onTap: () {
                Navigator.pop(context);
                _onSidebarTabSelected(6);
              },
            ),
          _buildDrawerItem(
            icon: Icons.search,
            label: "NIK Checker",
            onTap: () {
              Navigator.pop(context);
              _onSidebarTabSelected(3);
            },
          ),
          _buildDrawerItem(
            icon: Icons.lock_reset,
            label: "Change Password",
            onTap: () {
              Navigator.pop(context);
              _onSidebarTabSelected(4);
            },
          ),
          _buildDrawerItem(
            icon: Icons.bug_report,
            label: "Manage Bug Sender",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BugSenderPage(
                    sessionKey: sessionKey,
                    username: username,
                    role: role,
                  ),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFF4ECDC4), thickness: 0.5),
          _buildDrawerItem(
            icon: Icons.logout,
            label: "Logout",
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: softWhite.withOpacity(0.8), fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: softWhite, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: cyanLight),
        title: Text(label, style: TextStyle(color: softWhite)),
        onTap: onTap,
        hoverColor: primaryBlue.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, cyanLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("👤 Account Info",
                  style: TextStyle(color: softWhite, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            _infoCard(FontAwesomeIcons.user, "Username", username),
            _infoCard(FontAwesomeIcons.calendar, "Expired", expiredDate),
            _infoCard(FontAwesomeIcons.shieldAlt, "Role", role),
            const SizedBox(height: 30),
            // Buttons
            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset, color: softWhite),
              label: Text("Change Password", style: TextStyle(color: softWhite)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.bug_report, color: softWhite),
              label: Text("Manage Bug Sender", style: TextStyle(color: softWhite)),
              style: ElevatedButton.styleFrom(
                backgroundColor: tealAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BugSenderPage(
                      sessionKey: sessionKey,
                      username: username,
                      role: role,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: softWhite),
              label: Text("Logout", style: TextStyle(color: softWhite)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      color: cardBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cyanLight.withOpacity(0.3)),
      ),
      elevation: 2,
      shadowColor: cyanLight.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cyanLight),
            ),
            const SizedBox(width: 14),
            Text("$label:", style: TextStyle(color: softWhite.withOpacity(0.7), fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(value, style: TextStyle(color: softWhite, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text("Yoshimitsu",
            style: TextStyle(
              color: softWhite,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: cyanLight.withOpacity(0.8),
                  blurRadius: 10,
                ),
              ],
            )),
        backgroundColor: primaryDark,
        elevation: 0,
        iconTheme: IconThemeData(color: softWhite),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryBlue, cyanLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconButton(
              icon: Icon(FontAwesomeIcons.userCircle, color: softWhite),
              onPressed: _showAccountMenu,
            ),
          )
        ],
      ),
      drawer: _buildSidebar(),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBlue,
          border: Border(top: BorderSide(color: cyanLight.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: cyanLight,
          unselectedItemColor: softWhite.withOpacity(0.5),
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.whatsapp), label: "WhatsApp"),
            BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: "Tools"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  // 🎨 PALETTE BIRU - DEFINISI ULANG DI SINI (SUPAYA TIDAK ERROR)
  final Color primaryDark = const Color(0xFF0A1929);
  final Color primaryBlue = const Color(0xFF2B4F8C);
  final Color accentBlue = const Color(0xFF1E3A6F);
  final Color lightBlue = const Color(0xFF4A7DB5);
  final Color softWhite = const Color(0xFFF0F4FA);
  final Color cardBlue = const Color(0xFF13263E);
  final Color tealAccent = const Color(0xFF1B9C9C);
  final Color cyanLight = const Color(0xFF4ECDC4);
  final Color royalBlue = const Color(0xFF4169E1);

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(
            color: cyanLight,
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade800,
          child: Icon(Icons.error, color: cyanLight),
        ),
      );
    }
  }
}