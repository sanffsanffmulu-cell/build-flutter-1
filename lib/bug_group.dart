import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'services/api_config_service.dart';

class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage> with TickerProviderStateMixin {
  final linkGroupController = TextEditingController();

  String? _baseUrl;
  bool _isLoadingConfig = true;

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  bool _isSending = false;

  // Blue color palette
  final Color brightBlue = const Color(0xFF2196F3);
  final Color deepBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFF64B5F6);
  final Color darkBlue = const Color(0xFF0A2F4A);
  final Color neonBlue = const Color(0xFF00B0FF);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadServerUrl();
    _initializeVideoController();
    _startAnimations();
  }

  Future<void> _loadServerUrl() async {
    try {
      final url = await ApiConfig.baseUrl;
      setState(() {
        _baseUrl = url;
        _isLoadingConfig = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _initializeVideoController() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(25);
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  bool _isValidGroupLink(String input) {
    final regex = RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}');
    return regex.hasMatch(input);
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'owner':
        return Colors.red;
      case 'vip':
        return Colors.amber;
      case 'reseller':
        return brightBlue;
      default:
        return brightBlue;
    }
  }

  Future<void> _sendGroupBug() async {
    if (_isSending || _baseUrl == null) return;
    setState(() {
      _isSending = true;
    });
    _buttonController.forward().then((_) => _buttonController.reverse());

    final linkGroup = linkGroupController.text.trim();
    final key = widget.sessionKey;

    if (linkGroup.isEmpty || !_isValidGroupLink(linkGroup)) {
      _showAlert("❌ Invalid Link", "Please enter a valid WhatsApp group link.");
      setState(() => _isSending = false);
      return;
    }

    try {
      final url = Uri.parse("$_baseUrl/api/whatsapp/groupBug?key=$key&linkGroup=$linkGroup");
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("❌ Failed", data["message"] ?? "Failed to send group bug.");
      } else {
        _showSuccessPopup(linkGroup, data);
      }
    } catch (e) {
      _showAlert("❌ Error", "Terjadi kesalahan: ${e.toString()}");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSuccessPopup(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GroupBugSuccessDialog(
        linkGroup: linkGroup,
        data: data,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: brightBlue.withOpacity(0.3), width: 1),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron')),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: brightBlue)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!["vip", "owner"].contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1 + 0.1 * _glowAnimation.value),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3 + 0.2 * _glowAnimation.value),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.lock,
                      color: Colors.red,
                      size: 60,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "ACCESS DENIED",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This feature is only available for VIP and Owner users",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoadingConfig
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brightBlue)),
                  const SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: lightBlue, fontFamily: 'ShareTechMono')),
                ],
              ),
            )
          : Stack(
              children: [
                Container(color: Colors.black),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.98), Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildVideoBanner(),
                              const SizedBox(height: 20),
                              _buildGroupLinkCard(),
                              const SizedBox(height: 20),
                              _buildSendButton(),
                              const SizedBox(height: 14),
                              _buildFooterInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoBanner() {
    return Container(
      width: double.infinity,
      height: 190, // Lebih pendek (Sama seperti AttackPage)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28), // Sangat tumpul
        border: Border.all(color: brightBlue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: brightBlue.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video layer
            if (_videoInitialized && !_videoError)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [darkBlue, Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
              ),

            // Blur overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Foto aw.png TEPAT DI TENGAH
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 15, spreadRadius: 3, offset: const Offset(0, 4)),
                        BoxShadow(color: brightBlue.withOpacity(0.2), blurRadius: 10, spreadRadius: 1),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/aw.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [brightBlue, deepBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.role.toLowerCase() == "vip" ? FontAwesomeIcons.crown : FontAwesomeIcons.userShield,
                              color: Colors.white,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      letterSpacing: 1,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                  ),
                ],
              ),
            ),

            // Role - kiri bawah
            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14), // Tumpul
                  border: Border.all(color: _getRoleColor().withOpacity(0.6), width: 1),
                ),
                child: Text(
                  widget.role.toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(),
                    fontSize: 10,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ),

            // EXP - kanan bawah
            Positioned(
              right: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14), // Tumpul
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FontAwesomeIcons.calendarAlt, color: Colors.white.withOpacity(0.8), size: 9),
                    const SizedBox(width: 4),
                    Text(
                      widget.expiredDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                        fontWeight: FontWeight.bold,
                        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupLinkCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28), // Sangat tumpul
        border: Border.all(color: brightBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: brightBlue.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14), // Tumpul
                ),
                child: Icon(FontAwesomeIcons.users, color: brightBlue, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Group Link",
                style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Input Link
          TextField(
            controller: linkGroupController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: brightBlue,
            decoration: InputDecoration(
              hintText: "https://chat.whatsapp.com/...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: brightBlue.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(22), // Input sangat tumpul
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: brightBlue, width: 2),
                borderRadius: BorderRadius.circular(22),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(FontAwesomeIcons.link, color: brightBlue, size: 16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
          const SizedBox(height: 14),
          
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20), // Info box tumpul
              border: Border.all(color: brightBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.infoCircle, color: brightBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "This tool will automatically join the group, send a bug, and leave without leaving any trace.",
                    style: TextStyle(
                      color: brightBlue.withOpacity(0.8),
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
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

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [brightBlue, deepBlue, brightBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22), // Tombol sangat tumpul
            boxShadow: [
              BoxShadow(
                color: brightBlue.withOpacity(0.4 * _glowAnimation.value),
                blurRadius: 15 * _glowAnimation.value,
                spreadRadius: 2 * _glowAnimation.value,
              ),
              BoxShadow(color: brightBlue.withOpacity(0.2), blurRadius: 20, spreadRadius: 1),
            ],
          ),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: ElevatedButton.icon(
                  icon: _isSending
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(FontAwesomeIcons.users, color: Colors.white, size: 18),
                  label: Text(
                    _isSending ? "PROCESSING..." : "ATTACK GROUP",
                    style: const TextStyle(fontSize: 16, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 1.4, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSending ? null : _sendGroupBug,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22), // Footer sangat tumpul
        border: Border.all(color: brightBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.exclamationTriangle, color: brightBlue.withOpacity(0.5), size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "This tool will join the group, send a bug, and leave without any trace.",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'ShareTechMono'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _videoController.dispose();
    linkGroupController.dispose();
    super.dispose();
  }
}

class GroupBugSuccessDialog extends StatefulWidget {
  final String linkGroup;
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const GroupBugSuccessDialog({
    super.key,
    required this.linkGroup,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<GroupBugSuccessDialog> createState() => _GroupBugSuccessDialogState();
}

class _GroupBugSuccessDialogState extends State<GroupBugSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showDetails = false;

  final Color brightBlue = const Color(0xFF2196F3);
  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showDetails = true);
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenSize.width * 0.9, maxHeight: screenSize.height * 0.55),
        child: Container(
          width: screenSize.width * 0.9,
          height: screenSize.height * 0.55,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28), // Dialog sangat tumpul
            border: Border.all(color: brightBlue.withOpacity(0.3), width: 1),
            boxShadow: [BoxShadow(color: brightBlue.withOpacity(0.1), blurRadius: 15, spreadRadius: 3)],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: brightBlue.withOpacity(0.1 + 0.1 * _glowAnimation.value),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: brightBlue.withOpacity(0.3 + 0.2 * _glowAnimation.value), width: 2),
                            boxShadow: [BoxShadow(color: brightBlue.withOpacity(0.2 * _glowAnimation.value), blurRadius: 15, spreadRadius: 3)],
                          ),
                          child: Icon(FontAwesomeIcons.checkDouble, color: brightBlue, size: 40),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "GROUP BUG SENT!",
                      style: TextStyle(color: brightBlue, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_showDetails)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  bottom: 80,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(22), // Detail box tumpul
                          border: Border.all(color: brightBlue.withOpacity(0.2)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Attack Details:", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                              const SizedBox(height: 12),
                              _buildDetailRow("Group Link", widget.linkGroup),
                              _buildDetailRow("Success", widget.data["success"] == true ? "Yes" : "No"),
                              if (widget.data["canSendMessage"] != null)
                                _buildDetailRow("Can Send Msg", widget.data["canSendMessage"] == true ? "Yes" : "No"),
                              if (widget.data["groupInfo"] != null) ...[
                                _buildDetailRow("Group Name", widget.data["groupInfo"]["subject"] ?? "Unknown"),
                                _buildDetailRow("Members", widget.data["groupInfo"]["participants"]?.toString() ?? "Unknown"),
                                _buildDetailRow("Description", widget.data["groupInfo"]["desc"] ?? "No description"),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brightBlue.withOpacity(0.1),
                    foregroundColor: brightBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Tombol Done tumpul
                      side: BorderSide(color: brightBlue.withOpacity(0.3)),
                    ),
                  ),
                  child: Text("DONE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1, color: brightBlue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text("$label:", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontFamily: 'ShareTechMono')),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: brightBlue, fontSize: 12, fontFamily: 'ShareTechMono')),
          ),
        ],
      ),
    );
  }
}