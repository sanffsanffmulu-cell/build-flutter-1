import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';

import 'custom_bug.dart';
import 'bug_group.dart';
import 'home_page.dart';

class LxMenuPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;

  const LxMenuPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
  });

  @override
  State<LxMenuPage> createState() => _LxMenuPageState();
}

class _LxMenuPageState extends State<LxMenuPage> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _scrollController;
  final ScrollController _listScrollController = ScrollController();

  // Warna biru gelap utama
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color darkerBlue = Color(0xFF0A3A7A);
  static const Color accentBlue = Color(0xFF1565C0);
  static const Color lightDarkBlue = Color(0xFF1E88E5);
  
  // Daftar menu utama
  final List<Map<String, dynamic>> _menus = [
    {
      "title": "XCUBE BUG",
      "icon": FontAwesomeIcons.whatsapp,
      "description": "Bug tanpa custom",
      "note": "Gunakan langsung tanpa custom delay",
      "features": [
        "✓ Mudah Digunakan",
        "✓ Function Terbaru",
        "✓ All Work",
      ],
      "buttonText": "START MODULE",
      "page": "lx",
    },
    {
      "title": "CUSTOM BUG",
      "icon": FontAwesomeIcons.squareWhatsapp,
      "description": "Menu custom bug",
      "note": "Buat menu bug, delay pengiriman dan loops",
      "features": [
        "✓ Pengaturan Mudah",
        "✓ Support Multi Bug",
        "✓ Bebas Spam",
      ],
      "buttonText": "START MODULE",
      "page": "custom",
    },
    {
      "title": "GROUP BUG",
      "icon": FontAwesomeIcons.users,
      "description": "Menu group bug",
      "note": "Kirim bug ke group WhatsApp dengan mudah",
      "features": [
        "✓ Support Group",
        "✓ Auto Join",
        "✓ Multi Target",
      ],
      "buttonText": "START MODULE",
      "page": "group",
    },
    {
      "title": "CONTACT ADMIN",
      "icon": FontAwesomeIcons.headset,
      "description": "Hubungi Admin Jika Ada Kendala",
      "note": "Bantuan dan dukungan teknis 24/7",
      "features": [
        "⚠ Ada Bug",
        "⚠ Func Tidak Work",
        "⚠ Fitur Tidak Berfungsi",
      ],
      "buttonText": "CONTACT NOW",
      "page": "contact",
      "url": "https://t.me/maklolacurrr",
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Animasi glow yang berulang
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPage(String pageType, {String? url}) {
    if (pageType == "contact" && url != null) {
      _launchUrl(url);
      return;
    }
    
    switch (pageType) {
      case "custom":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomAttackPage(
              username: widget.username,
              password: widget.password,
              listPayload: widget.listPayload,
              role: widget.role,
              expiredDate: widget.expiredDate,
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
      case "group":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupBugPage(
              username: widget.username,
              password: widget.password,
              role: widget.role,
              expiredDate: widget.expiredDate,
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
      case "lx":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttackPage(
              username: widget.username,
              password: widget.password,
              listBug: widget.listBug,
              role: widget.role,
              expiredDate: widget.expiredDate,
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "XCUBE MENU",
          style: TextStyle(
            color: darkBlue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: "Orbitron",
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan efek glow
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 10),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [darkBlue, accentBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "PILIH MENU YANG TERSEDIA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: "ShareTechMono",
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // List Menu Vertical dengan Scroll
              Expanded(
                child: ListView.builder(
                  controller: _listScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _menus.length,
                  itemBuilder: (context, index) {
                    return _buildCard(_menus[index], index);
                  },
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Text(
                  "Semua menu telah diuji: cobaan tanpa gimmick real work 100%",
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 12,
                    fontFamily: "ShareTechMono",
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> menu, int index) {
    final isContact = menu["page"] == "contact";
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            // Warna solid #212121
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(24),
            // Tepian biru gelap dengan efek gradient
            border: Border.all(
              color: darkBlue.withOpacity(0.6 + (_glowAnimation.value * 0.4)),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: darkBlue.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToPage(menu["page"], url: menu["url"]),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Icon dan Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                darkBlue.withOpacity(0.2),
                                accentBlue.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: darkBlue.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            menu["icon"],
                            color: darkBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            menu["title"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Orbitron",
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      menu["description"],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: "ShareTechMono",
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Note Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: darkBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: darkBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              menu["note"],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontFamily: "ShareTechMono",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Features
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: (menu["features"] as List<String>).map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: darkBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: darkBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isContact
                              ? [const Color(0xFFFF6B6B), const Color(0xFFFF4757)]
                              : [darkBlue, accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isContact
                                ? const Color(0xFFFF4757).withOpacity(0.3)
                                : darkBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _navigateToPage(menu["page"], url: menu["url"]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isContact ? Icons.telegram : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              menu["buttonText"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: "ShareTechMono",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}