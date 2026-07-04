import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart';
import 'subdomain_finder_page.dart';
import 'anime.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Tools yang tersedia (hanya dari import)
  final List<Map<String, dynamic>> _availableTools = [
    {
      'title': 'Chat AI',
      'description': 'AI-powered conversation',
      'icon': Icons.chat,
      'page': (BuildContext context, String sessionKey) => ChatAIPage(sessionKey: sessionKey),
      'color': const Color(0xFF00B4FF),
    },
    {
      'title': 'NIK Check',
      'description': 'Validate Indonesian identity',
      'icon': Icons.badge,
      'page': (BuildContext context, String sessionKey) => NIKCheckPage(sessionKey: sessionKey),
      'color': const Color(0xFF00D4FF),
    },
    {
      'title': 'Phone Lookup',
      'description': 'Find phone number info',
      'icon': Icons.phone,
      'page': (BuildContext context, String sessionKey) => PhoneLookupPage(sessionKey: sessionKey),
      'color': const Color(0xFFFF9800), // Fixed: changed back to orange
    },
    {
      'title': 'Subdomain Finder',
      'description': 'Discover subdomains',
      'icon': Icons.language,
      'page': (BuildContext context, String sessionKey) => SubdomainFinderPage(sessionKey: sessionKey),
      'color': const Color(0xFF9C27B0), // Fixed: changed back to purple
    },
    {
      'title': 'Anime',
      'description': 'Streaming, 18+',
      'icon': Icons.movie,
      'page': (BuildContext context, String sessionKey) => const HomeAnimePage(),
      'color': const Color(0xFFE91E63), // Fixed: changed back to pink
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00B4FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "TOOLS XCUBE",
          style: TextStyle(
            color: Color(0xFF00B4FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildToolsGrid(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "${_availableTools.length} item",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B4FF).withOpacity(0.15),
            const Color(0xFF0099FF).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00B4FF).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4FF).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00B4FF),
                      Color(0xFF0099FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B4FF).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.build,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "XCUBE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "Gateway Tools",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00B4FF).withOpacity(0.2),
                  const Color(0xFF0099FF).withOpacity(0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF00B4FF).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Tools Xcube",
                  style: TextStyle(
                    color: const Color(0xFF00B4FF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF00B4FF).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4FF), Color(0xFF0099FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_availableTools.length} item",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _availableTools.length,
      itemBuilder: (context, index) {
        final tool = _availableTools[index];
        return _buildToolCard(tool);
      },
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => tool['page'](context, widget.sessionKey),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tool['color'].withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tool['color'].withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tool['color'].withOpacity(0.3),
                    tool['color'].withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tool['icon'],
                color: tool['color'],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tool['title'],
              style: TextStyle(
                color: tool['color'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: tool['color'].withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              tool['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}