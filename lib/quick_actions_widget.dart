import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:ui';

import 'sender_page.dart';
import 'lx_menu_page.dart';
import 'ddos_page.dart';
import 'ddos_panel.dart';
import 'telegram.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'alquran_page.dart';
import 'chat_page.dart';
import 'device_dashboard.dart';

class QuickActionsWidget extends StatefulWidget {
  final String username;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;

  const QuickActionsWidget({
    super.key,
    required this.username,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> with TickerProviderStateMixin {
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;
  int _itemCount = 0;
  double _pageValue = 0.0;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Daftar card dengan warna masing-masing
  late List<Map<String, dynamic>> _originalCards;
  late List<Map<String, dynamic>> _infiniteCards;

  @override
  void initState() {
    super.initState();
    
    // Animasi glow yang berulang
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    
    // Inisialisasi original cards dengan urutan
    _originalCards = [
      {
        "type": "feature",
        "title": "Manage Bug Sender",
        "subtitle": "Pairing & Configuration",
        "color": const Color(0xFF9C27B0),
        "gradientStart": const Color(0xFF9C27B0),
        "gradientEnd": const Color(0xFF4A148C),
        "page": "sender",
      },
      {
        "title": "Rat", // 🔥 NEW
        "subtitle": "Monitor Device",
        "color": const Color(0xFF00BCD4),
        "gradientStart": const Color(0xFF00BCD4),
        "gradientEnd": const Color(0xFF006064),
        "page": "rat",
      },
      {
        "type": "feature",
        "title": "Room Chat",
        "subtitle": "Global Communication",
        "color": const Color(0xFF3F51B5),
        "gradientStart": const Color(0xFF3F51B5),
        "gradientEnd": const Color(0xFF1A237E),
        "page": "chat",
      },
      {
        "type": "feature",
        "title": "Xcube Bug",
        "subtitle": "WhatsApp Bug Menu",
        "color": const Color(0xFF25D366),
        "gradientStart": const Color(0xFF25D366),
        "gradientEnd": const Color(0xFF075E54),
        "page": "lx",
      },
      {
        "type": "feature",
        "title": "Al-Qur'an",
        "subtitle": "Lengkap & Terjemahan",
        "color": const Color(0xFF4CAF50),
        "gradientStart": const Color(0xFF4CAF50),
        "gradientEnd": const Color(0xFF2E7D32),
        "page": "quran",
      },
      {
        "type": "feature",
        "title": "Telegram",
        "subtitle": "Spam Module",
        "color": const Color(0xFF0088cc),
        "gradientStart": const Color(0xFF0088cc),
        "gradientEnd": const Color(0xFF004C7A),
        "page": "telegram",
      },
      {
        "type": "feature",
        "title": "Tools",
        "subtitle": "Utilities & Settings",
        "color": const Color(0xFFFF9800),
        "gradientStart": const Color(0xFFFF9800),
        "gradientEnd": const Color(0xFFF57C00),
        "page": "tools",
      },
      {
        "type": "feature",
        "title": "DDoS Panel",
        "subtitle": "Attack Panel",
        "color": const Color(0xFFF44336),
        "gradientStart": const Color(0xFFF44336),
        "gradientEnd": const Color(0xFFB71C1C),
        "page": "ddos",
      },
    ];

    // Tambahkan Reseller jika role sesuai
    if (widget.role == "reseller" || widget.role == "owner") {
      _originalCards.add({
        "type": "feature",
        "title": "Reseller",
        "subtitle": "Manage Users & Panel",
        "color": const Color(0xFF3F51B5),
        "gradientStart": const Color(0xFF3F51B5),
        "gradientEnd": const Color(0xFF1A237E),
        "page": "reseller",
      });
    }

    // Tambahkan Admin jika role owner
    if (widget.role == "owner") {
      _originalCards.add({
        "type": "feature",
        "title": "Admin",
        "subtitle": "Full Control Panel",
        "color": const Color(0xFFE91E63),
        "gradientStart": const Color(0xFFE91E63),
        "gradientEnd": const Color(0xFF880E4F),
        "page": "admin",
      });
    }

    // Buat infinite cards dengan duplikasi
    _infiniteCards = [
      ..._originalCards,
      ..._originalCards,
      ..._originalCards,
    ];
    
    _itemCount = _infiniteCards.length;
    
    // PageController dengan viewportFraction 0.65 untuk card lebih besar
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: _originalCards.length + 1,
    );
    
    // Listener untuk update page value
    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page ?? 0;
      });
      
      _checkInfiniteLoop();
    });
    
    // Auto scroll setiap 4 detik
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _checkInfiniteLoop() {
    if (!_pageController.hasClients) return;
    
    final currentPage = _pageController.page?.toInt() ?? 0;
    
    if (currentPage < _originalCards.length) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(
            currentPage + _originalCards.length
          );
        }
      });
    }
    else if (currentPage >= _originalCards.length * 2) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(
            currentPage - _originalCards.length
          );
        }
      });
    }
    
    final adjustedPage = (currentPage % _originalCards.length);
    if (adjustedPage != _currentPage) {
      setState(() {
        _currentPage = adjustedPage;
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.removeListener(_checkInfiniteLoop);
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToPage(String? pageType) {
    if (pageType == null) return;
    
    switch (pageType) {
      case "sender":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SenderPage(
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
      case "rat":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceDashboardPage(),
          ),
        );
        break;
      case "chat":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
      case "lx":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LxMenuPage(
              username: widget.username,
              password: '',
              role: widget.role,
              sessionKey: widget.sessionKey,
              expiredDate: widget.expiredDate,
              listBug: widget.listBug,
              listPayload: widget.listPayload,
            ),
          ),
        );
        break;
      case "quran":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AlQuranPage(),
          ),
        );
        break;
      case "telegram":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelegramSpamPage(
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
      case "tools":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToolsPage(
              sessionKey: widget.sessionKey,
              userRole: widget.role,
            ),
          ),
        );
        break;
      case "ddos":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttackPanel(
              sessionKey: widget.sessionKey,
              listDDoS: widget.listDDoS,
            ),
          ),
        );
        break;
      case "reseller":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerPage(
              keyToken: widget.sessionKey,
            ),
          ),
        );
        break;
      case "admin":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPage(
              sessionKey: widget.sessionKey,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header iX-00-25 dan Quick Assistance
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF0D47A1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      "XCUBE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Orbitron",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Quick Assistance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Orbitron",
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  "Navigasi Instan",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: "ShareTechMono",
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card Auto-Slide dengan efek smooth manual & otomatis
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _itemCount,
            itemBuilder: (context, index) {
              final cardData = _infiniteCards[index];
              return _buildSmoothCard(cardData, index);
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _originalCards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? _originalCards[index]["color"]
                    : Colors.white.withOpacity(0.3),
                boxShadow: _currentPage == index
                    ? [
                        BoxShadow(
                          color: _originalCards[index]["color"].withOpacity(0.5),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmoothCard(Map<String, dynamic> cardData, int absoluteIndex) {
    // Hitung posisi relatif
    final int relativeIndex = absoluteIndex % _originalCards.length;
    final bool isActive = relativeIndex == _currentPage;
    
    // Hitung scale berdasarkan posisi dengan interpolasi smooth
    double scale = 1.0;
    double opacity = 1.0;
    double glowIntensity = 0.0;
    
    if (_pageController.hasClients) {
      double page = _pageValue;
      double difference = (absoluteIndex - page).abs();
      
      // Smooth interpolation untuk scale
      if (difference < 1.0) {
        // Card yang mendekati tengah - smooth transition
        scale = 1.0 - (difference * 0.2); // scale 1.0 - 0.8
        opacity = 1.0;
        glowIntensity = 1.0 - difference;
      } else {
        // Card yang jauh
        scale = 0.8;
        opacity = 0.7;
        glowIntensity = 0.0;
      }
    } else {
      scale = isActive ? 1.0 : 0.8;
      opacity = isActive ? 1.0 : 0.7;
      glowIntensity = isActive ? 1.0 : 0.0;
    }

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardData["gradientStart"],
                      cardData["gradientEnd"],
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    if (glowIntensity > 0)
                      BoxShadow(
                        color: cardData["color"].withOpacity(_glowAnimation.value * 0.6 * glowIntensity),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToPage(cardData["page"]),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Icon lebih besar
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              _getIconForCard(cardData["title"]),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Teks
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cardData["title"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cardData["subtitle"],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Tap indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Tap",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForCard(String title) {
    if (title.contains("Manage Bug")) return Icons.settings_remote;
    if (title.contains("Rat")) return Icons.devices;
    if (title.contains("Room Chat")) return Icons.chat;
    if (title.contains("LX")) return FontAwesomeIcons.whatsapp;
    if (title.contains("Qur'an")) return Icons.menu_book;
    if (title.contains("Telegram")) return Icons.telegram;
    if (title.contains("Tools")) return Icons.build;
    if (title.contains("DDoS")) return Icons.flash_on;
    if (title.contains("Reseller")) return Icons.person_add;
    if (title.contains("Admin")) return Icons.admin_panel_settings;
    return Icons.widgets;
  }
}