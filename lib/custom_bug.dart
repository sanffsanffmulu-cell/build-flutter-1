import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';
import '../services/api_config_service.dart'; // Import ApiConfigService

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role;
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");
  
  // Dynamic base URL - REPLACE hardcoded URL
  String? _baseUrl;
  bool _isLoadingConfig = true;
  String? _configError;

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
  List<Map<String, dynamic>> selectedBugs = [];
  bool _isSending = false;
  bool _useGlobalSender = true; // true = global, false = private
  int _activeStep = 0;
  List<Map<String, dynamic>> payloadQueue = []; // Queue for ordered payloads

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBaseUrlAndInitialize(); // New method to load base URL
    _startAnimations();
  }

  // New method to load base URL from Gist
  Future<void> _loadBaseUrlAndInitialize() async {
    try {
      final apiConfig = ApiConfigService();
      _baseUrl = await apiConfig.getBaseUrl();
      print('✅ CustomAttackPage - Base URL loaded: $_baseUrl');
      
      setState(() {
        _isLoadingConfig = false;
      });
      
      _initializeVideoController();
      _setDefaultBugs();
      
    } catch (e) {
      print('❌ CustomAttackPage - Failed to load base URL: $e');
      setState(() {
        _configError = 'Failed to load server configuration: $e';
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

  void _setDefaultBugs() {
    // No default selection
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
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    } catch (e) {
      print('Video controller creation error: $e');
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

  void _toggleBugSelection(Map<String, dynamic> bug) {
    setState(() {
      final index = selectedBugs.indexWhere((b) => b['bug_id'] == bug['bug_id']);
      if (index != -1) {
        selectedBugs.removeAt(index);
      } else {
        selectedBugs.add(bug);
      }
    });
  }

  void _addToQueue(Map<String, dynamic> bug) {
    setState(() {
      payloadQueue.add(bug);
    });
  }

  void _removeFromQueue(int index) {
    setState(() {
      payloadQueue.removeAt(index);
    });
  }

  void _moveQueueItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = payloadQueue.removeAt(oldIndex);
      payloadQueue.insert(newIndex, item);
    });
  }

  Future<void> _sendCustomBug() async {
    if (_isSending) return;
    
    // Check if base URL is loaded
    if (_baseUrl == null) {
      _showAlert("❌ Config Error", "Server configuration not loaded. Please try again.");
      await _loadBaseUrlAndInitialize();
      if (_baseUrl == null) return;
    }

    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;
    final qty = int.tryParse(qtyController.text) ?? 1;
    final delay = int.tryParse(delayController.text) ?? 100;
    final senderType = _useGlobalSender ? "global" : "private";

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    if (payloadQueue.isEmpty) {
      _showAlert("❌ No Payload Selected", "Please add at least one payload to the queue.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      // Create comma-separated list of bugs from queue
      final bugsParam = payloadQueue.map((b) => b['bug_id']).join(',');

      // Use dynamic base URL
      final res = await http.get(
        Uri.parse("$_baseUrl/api/whatsapp/customBug?key=$key&target=$target&bug=$bugsParam&qty=$qty&delay=$delay&senderType=$senderType")
      ).timeout(const Duration(seconds: 30));
      
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("❌ Failed", data["message"] ?? "Failed to send custom bug.");
      } else {
        setState(() {
          _activeStep = 2;
        });
        _showSuccessPopup(target, data["details"]);
      }
    } catch (e) {
      print('Error sending custom bug: $e');
      _showAlert("❌ Error", "Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
        if (_activeStep != 2) _activeStep = 0;
      });
    }
  }

  void _showSuccessPopup(String target, Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSuccessDialog(
        target: target,
        details: details,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() {
            _activeStep = 0;
          });
        },
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron')),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF2196F3))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only allow access to VIP and Owner roles
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

    // Loading config state
    if (_isLoadingConfig) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: const Color(0xFF2196F3),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Loading server configuration...",
                style: TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
              ),
              const SizedBox(height: 10),
              Text(
                "Fetching from GitHub Gist",
                style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'ShareTechMono'),
              ),
            ],
          ),
        ),
      );
    }

    // Error config state
    if (_configError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                ),
                child: Icon(Icons.error_outline, color: const Color(0xFF2196F3), size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "Configuration Error",
                style: TextStyle(
                  color: const Color(0xFF2196F3),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron'
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _configError!,
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'ShareTechMono'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingConfig = true;
                    _configError = null;
                  });
                  _loadBaseUrlAndInitialize();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("RETRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background
          _videoInitialized && !_videoError
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A0A0A),
                        Color(0xFF121212),
                        Color(0xFF1A1A1A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Main content
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
                        // User info header (solid)
                        _buildUserInfoHeader(),

                        const SizedBox(height: 20),

                        // Target input card
                        _buildTargetInputCard(),

                        const SizedBox(height: 14),

                        // Payload and Queue section
                        _buildPayloadAndQueueSection(),

                        const SizedBox(height: 14),

                        // Quantity and Delay card
                        _buildQuantityDelayCard(),

                        const SizedBox(height: 20),

                        // Send button
                        _buildSendButton(),

                        const SizedBox(height: 14),

                        // Footer info
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

  Widget _buildUserInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              widget.role.toLowerCase() == "vip"
                  ? FontAwesomeIcons.crown
                  : FontAwesomeIcons.userShield,
              color: const Color(0xFF2196F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.role.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  FontAwesomeIcons.calendarAlt,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(height: 2),
                Text(
                  "EXP",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 9,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                Text(
                  widget.expiredDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
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
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FontAwesomeIcons.phone,
                  color: Color(0xFF2196F3),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Target Number",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: targetController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: const Color(0xFF2196F3),
            decoration: InputDecoration(
              hintText: "e.g. +62xxxxxxxxx",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFF2196F3).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.globe,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Use international format without 0 or +",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadAndQueueSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Queue Section (Left)
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.list,
                      color: const Color(0xFF2196F3),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Queue (${payloadQueue.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const Spacer(),
                    if (payloadQueue.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            payloadQueue.clear();
                          });
                        },
                        child: Text(
                          "Clear All",
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.8),
                            fontSize: 11,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (payloadQueue.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            FontAwesomeIcons.inbox,
                            color: Colors.white.withOpacity(0.3),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No payloads in queue",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                          Text(
                            "Tap + to add payloads",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: payloadQueue.length,
                      onReorder: _moveQueueItem,
                      itemBuilder: (context, index) {
                        final bug = payloadQueue[index];
                        return Container(
                          key: ValueKey(bug['bug_id']),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.gripVertical,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bug['bug_name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "ID: ${bug['bug_id']}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 9,
                                        fontFamily: 'ShareTechMono',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeFromQueue(index),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.trash,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Payload Selection Section (Right)
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.bug,
                      color: const Color(0xFF2196F3),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Payloads (${widget.listPayload.length})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.listPayload.length,
                    itemBuilder: (context, index) {
                      final bug = widget.listPayload[index];
                      final isInQueue = payloadQueue.any((b) => b['bug_id'] == bug['bug_id']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bug['bug_name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "ID: ${bug['bug_id']}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 9,
                                      fontFamily: 'ShareTechMono',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isInQueue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "IN QUEUE",
                                  style: TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => _addToQueue(bug),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.plus,
                                    color: Color(0xFF2196F3),
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityDelayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
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
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FontAwesomeIcons.slidersH,
                  color: Color(0xFF2196F3),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Quantity & Delay",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Global Sender Toggle
              Row(
                children: [
                  const Text(
                    "Global",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Switch(
                    value: _useGlobalSender,
                    onChanged: (value) {
                      setState(() {
                        _useGlobalSender = value;
                      });
                    },
                    activeColor: const Color(0xFF2196F3),
                  ),
                  const Text(
                    "Private",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF2196F3),
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    hintText: "1-200",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: const Color(0xFF2196F3).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: delayController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF2196F3),
                  enabled: !_useGlobalSender,
                  decoration: InputDecoration(
                    labelText: "Delay (ms)",
                    labelStyle: TextStyle(
                      color: !_useGlobalSender
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.3),
                    ),
                    hintText: "10-1000",
                    hintStyle: TextStyle(
                      color: !_useGlobalSender
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: !_useGlobalSender
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.02),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: !_useGlobalSender
                            ? const Color(0xFF2196F3).withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: !_useGlobalSender
                            ? const Color(0xFF2196F3)
                            : Colors.white.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
          if (_useGlobalSender)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.infoCircle,
                    color: Colors.white.withOpacity(0.5),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Note: Delay is fixed at 500ms for Global sender",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 18),
              label: Text(
                _isSending ? "SENDING..." : "SEND CUSTOM PAYLOAD",
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSending ? null : _sendCustomBug,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: Colors.white.withOpacity(0.5),
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Custom attack with multiple payloads. Drag to reorder queue. Use responsibly.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
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
    if (_videoController != null) {
      _videoController.dispose();
    }
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }
}

// Custom success dialog for custom attack
class CustomSuccessDialog extends StatefulWidget {
  final String target;
  final Map<String, dynamic> details;
  final VoidCallback onDismiss;

  const CustomSuccessDialog({
    super.key,
    required this.target,
    required this.details,
    required this.onDismiss,
  });

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Show details after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showDetails = true;
        });
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
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Success icon and title
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
                            color: const Color(0xFF2196F3).withOpacity(0.1 + 0.1 * _glowAnimation.value),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withOpacity(0.3 + 0.2 * _glowAnimation.value),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.2 * _glowAnimation.value),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            FontAwesomeIcons.checkDouble,
                            color: Color(0xFF2196F3),
                            size: 40,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "CUSTOM ATTACK SENT!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Attack details
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Attack Details:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow("Target", widget.target),
                            _buildDetailRow("Sender Type", widget.details["senderType"].toString()),
                            _buildDetailRow("Payloads", widget.details["bugs"].toString()),
                            _buildDetailRow("Quantity", widget.details["qty"].toString()),
                            _buildDetailRow("Delay", "${widget.details["delay"]}ms"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Close button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: const Text(
                    "DONE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}