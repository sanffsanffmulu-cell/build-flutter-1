import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'services/api_config_service.dart';

class AttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const AttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();

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
  String selectedBugId = "";
  bool _isSending = false;
  bool _isSuccess = false;

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
    _setDefaultBug();
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

  void _setDefaultBug() {
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }
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

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  String _getSelectedBugName() {
    if (selectedBugId.isEmpty) return "Select Bug...";
    try {
      final bug = widget.listBug.firstWhere((b) => b['bug_id'] == selectedBugId);
      return bug['bug_name'] ?? 'Select Bug...';
    } catch (e) {
      return "Select Bug...";
    }
  }

  void _showBugSelectionSheet() {
    String tempSelectedId = selectedBugId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.98),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: brightBlue.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.virus, color: brightBlue, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "Select Bug",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "1 selected",
                          style: TextStyle(
                            color: brightBlue.withOpacity(0.7),
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // List Bug
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.listBug.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final bug = widget.listBug[index];
                        final isSelected = tempSelectedId == bug['bug_id'];

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              tempSelectedId = bug['bug_id'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? brightBlue.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? brightBlue : brightBlue.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Custom Radio/Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? brightBlue : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? brightBlue : Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bug['bug_name'] ?? 'Unknown Bug',
                                        style: TextStyle(
                                          color: isSelected ? brightBlue : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (bug['description'] != null)
                                        Text(
                                          bug['description'],
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
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

                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [brightBlue, deepBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: brightBlue.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedBugId = tempSelectedId;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          "APPLY",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendBug() async {
    if (_isSending || _baseUrl == null) return;
    setState(() {
      _isSending = true;
    });
    _buttonController.forward().then((_) => _buttonController.reverse());

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: 62xxx), bukan 08xxx.");
      setState(() => _isSending = false);
      return;
    }

    try {
      final url = Uri.parse("$_baseUrl/api/whatsapp/sendBug?key=$key&target=$target&bug=$selectedBugId");
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("⏳ Cooldown", "Tunggu beberapa saat sebelum mengirim lagi.");
      } else if (data["senderOn"] == false) {
        _showAlert("⚠️ Gagal", "Gagal mengirim bug. Sender Kosong, Hubungi Seller.");
      } else if (data["valid"] == false) {
        _showAlert("❌ Key Invalid", "Session key tidak valid. Silakan login ulang.");
      } else if (data["sended"] == false) {
        _showAlert("⚠️ Gagal", "Gagal mengirim bug. Mungkin server sedang maintenance.");
      } else {
        setState(() => _isSuccess = true);
        _showSuccessPopup(target);
      }
    } catch (e) {
      _showAlert("❌ Error", "Terjadi kesalahan: ${e.toString()}");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSuccessPopup(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessVideoDialog(
        target: target,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() => _isSuccess = false);
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

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'owner':
        return Colors.red;
      case 'vip':
        return Colors.amber;
      default:
        return brightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              _buildCombinedCard(),
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
      height: 190, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28), 
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

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

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
                            child: const Icon(FontAwesomeIcons.user, color: Colors.white, size: 32),
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

            Positioned(
              left: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
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

            Positioned(
              right: 14,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
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

  Widget _buildCombinedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: brightBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: brightBlue.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Number
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(FontAwesomeIcons.phone, color: brightBlue, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Target Number",
                style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: brightBlue,
            decoration: InputDecoration(
              hintText: "e.g. 62xxxxxxxxx",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: brightBlue.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(22), 
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
                child: Icon(FontAwesomeIcons.globe, color: brightBlue, size: 16),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),

          const SizedBox(height: 12), 

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, brightBlue.withOpacity(0.3), Colors.transparent]),
            ),
          ),

          const SizedBox(height: 12), 

          // Bug Type Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(FontAwesomeIcons.whatsapp, color: brightBlue, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Bug Type",
                style: TextStyle(color: Colors.white, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tombol Select Bug (Menggantikan Dropdown)
          GestureDetector(
            onTap: _showBugSelectionSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22), 
                border: Border.all(color: brightBlue.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: brightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(FontAwesomeIcons.virus, color: brightBlue, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getSelectedBugName(),
                        style: TextStyle(
                          color: selectedBugId.isNotEmpty ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: selectedBugId.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Icon(FontAwesomeIcons.chevronUp, color: brightBlue, size: 14), // Panah ke atas karena menu dari bawah
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(FontAwesomeIcons.infoCircle, color: brightBlue.withOpacity(0.5), size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Tap to select the appropriate bug type",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'ShareTechMono'),
                ),
              ),
            ],
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
            borderRadius: BorderRadius.circular(22), 
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
                      : Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 18),
                  label: Text(
                    _isSending ? "SENDING..." : "SEND BUG",
                    style: const TextStyle(fontSize: 16, fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 1.4, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSending ? null : _sendBug,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: brightBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.exclamationTriangle, color: brightBlue.withOpacity(0.5), size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Use this tool responsibly. We are not responsible for any misuse.",
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
    targetController.dispose();
    super.dispose();
  }
}

class SuccessVideoDialog extends StatefulWidget {
  final String target;
  final VoidCallback onDismiss;

  const SuccessVideoDialog({super.key, required this.target, required this.onDismiss});

  @override
  State<SuccessVideoDialog> createState() => _SuccessVideoDialogState();
}

class _SuccessVideoDialogState extends State<SuccessVideoDialog> with TickerProviderStateMixin {
  late VideoPlayerController _successVideoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showSuccessInfo = false;
  bool _videoError = false;
  bool _videoInitialized = false;

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
    _initializeSuccessVideo();
  }

  void _initializeSuccessVideo() {
    try {
      _successVideoController = VideoPlayerController.asset('assets/videos/splash.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _videoInitialized = true);
            _successVideoController.play();
            _successVideoController.addListener(() {
              if (_successVideoController.value.position >= _successVideoController.value.duration) {
                _showSuccessMessage();
              }
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() => _videoError = true);
            Future.delayed(const Duration(milliseconds: 500), () => _showSuccessMessage());
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() => _videoError = true);
        Future.delayed(const Duration(milliseconds: 500), () => _showSuccessMessage());
      }
    }
  }

  void _showSuccessMessage() {
    if (mounted) {
      setState(() => _showSuccessInfo = true);
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _successVideoController.dispose();
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
        constraints: BoxConstraints(maxWidth: screenSize.width * 0.9, maxHeight: screenSize.height * 0.45),
        child: Container(
          width: screenSize.width * 0.9,
          height: screenSize.height * 0.45,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: brightBlue.withOpacity(0.3), width: 1),
            boxShadow: [BoxShadow(color: brightBlue.withOpacity(0.1), blurRadius: 15, spreadRadius: 3)],
          ),
          child: Stack(
            children: [
              if (!_showSuccessInfo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _videoInitialized && !_videoError
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _successVideoController.value.size.width,
                              height: _successVideoController.value.size.height,
                              child: VideoPlayer(_successVideoController),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(colors: [Colors.black, brightBlue.withOpacity(0.1), Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, child) {
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: brightBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: brightBlue.withOpacity(0.3 * _glowAnimation.value), width: 2),
                                        boxShadow: [BoxShadow(color: brightBlue.withOpacity(0.2 * _glowAnimation.value), blurRadius: 15, spreadRadius: 3)],
                                      ),
                                      child: Icon(FontAwesomeIcons.check, color: brightBlue, size: 50),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Text("SUCCESS", style: TextStyle(color: brightBlue, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 3)),
                              ],
                            ),
                          ),
                        ),
                ),
              if (_showSuccessInfo)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.98)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: brightBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: brightBlue.withOpacity(0.3 * _glowAnimation.value), width: 2),
                                  boxShadow: [BoxShadow(color: brightBlue.withOpacity(0.2 * _glowAnimation.value), blurRadius: 15, spreadRadius: 3)],
                                ),
                                child: Icon(FontAwesomeIcons.checkDouble, color: brightBlue, size: 36),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text("Attack Successful!", style: TextStyle(color: brightBlue, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
                          const SizedBox(height: 10),
                          Text("Bug successfully sent to ${widget.target}", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontFamily: 'ShareTechMono'), textAlign: TextAlign.center),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brightBlue.withOpacity(0.1),
                              foregroundColor: brightBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: brightBlue.withOpacity(0.3), width: 1)),
                            ),
                            child: Text("DONE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1, color: brightBlue)),
                          ),
                        ],
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
}