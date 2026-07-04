import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'services/api_config_service.dart'; // Import ApiConfigService

// HAPUS baris ini:
// const String baseUrl = "http://kontoljanddos.panel-host.biz.id:3881";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  bool isLoading = false;
  String? androidId;
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Tambahkan variable untuk menyimpan baseUrl
  String? _baseUrl;
  bool _isLoadingConfig = true;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBaseUrlAndInit();
    
    _initAnimations();
    _initVideoPlayer();
  }
  
  Future<void> _loadBaseUrlAndInit() async {
    setState(() {
      _isLoadingConfig = true;
    });
    
    try {
      print('🌐 LoginPage: Fetching ACTIVE URL from Gist...');
      final apiConfig = ApiConfigService();
      _baseUrl = await apiConfig.getBaseUrl();
      
      if (_baseUrl != null && _baseUrl!.isNotEmpty) {
        print('✅ Base URL loaded: $_baseUrl');
        setState(() {
          _isLoadingConfig = false;
          _retryCount = 0;
        });
        
        // Setelah baseUrl didapat, jalankan initLogin
        await initLogin();
      } else {
        throw Exception('Base URL is empty');
      }
      
    } catch (e) {
      print('❌ Error loading base URL: $e');
      
      // Retry mechanism dengan exponential backoff
      if (_retryCount < 3) {
        _retryCount++;
        final delay = Duration(seconds: _retryCount * 2);
        print('🔄 Retry $_retryCount/3 in ${delay.inSeconds} seconds...');
        
        Future.delayed(delay, () {
          if (mounted) {
            _loadBaseUrlAndInit();
          }
        });
      } else {
        // Fallback ke URL default jika gagal semua retry
        setState(() {
          _baseUrl = "http://kontoljanddos.panel-host.biz.id:3881";
          _isLoadingConfig = false;
        });
        print('⚠️ Using fallback base URL: $_baseUrl');
        
        // Show error snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Using fallback server. Configuration may be outdated.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Tetap jalankan initLogin dengan fallback
        await initLogin();
      }
    }
  }
  
  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }
  
  void _initVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/login.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.setLooping(true);
          _videoController.play();
          _videoController.setVolume(0);
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null && _baseUrl != null) {
      final uri = Uri.parse(
        "$_baseUrl/api/auth/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        final data = jsonDecode(res.body);

        if (data['valid'] == true && mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/splash',
            arguments: {
              'username': savedUser,
              'password': savedPass,
              'role': data['role'],
              'key': data['key'],
              'expiredDate': data['expiredDate'],
              'listBug': data['listBug'] ?? [],
              'listPayload': data['listPayload'] ?? [],
              'listDDoS': data['listDDoS'] ?? [],
              'news': data['news'] ?? [],
            },
          );
        }
      } catch (e) {
        print('Auto login error: $e');
      }
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("⚠️ Error", "Username and password are required.");
      return;
    }
    
    if (_baseUrl == null) {
      _showAlert("⚠️ Error", "Loading server configuration, please try again.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$_baseUrl/api/auth/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      ).timeout(const Duration(seconds: 15));

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showAlert("⛔ Access Expired", "Your access has expired.\nPlease renew it.", showContact: true);
      } else if (validData['valid'] != true) {
        _showAlert("🚫 Login Failed", "Invalid username or password.", showContact: true);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/splash',
            arguments: {
              'username': username,
              'password': password,
              'role': validData['role'],
              'key': validData['key'],
              'expiredDate': validData['expiredDate'],
              'listBug': validData['listBug'] ?? [],
              'listPayload': validData['listPayload'] ?? [],
              'listDDoS': validData['listDDoS'] ?? [],
              'news': validData['news'] ?? [],
            },
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      _showAlert("🌐 Connection Error", "Failed to connect to the server.\nPlease check your connection.");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showAlert(String title, String msg, {bool showContact = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title.contains("Error") || title.contains("Failed")
                    ? Icons.error_outline
                    : title.contains("Expired")
                    ? Icons.timer_off
                    : Icons.info_outline,
                color: title.contains("Error") || title.contains("Failed")
                    ? Colors.redAccent
                    : title.contains("Expired")
                    ? Colors.amber
                    : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          if (showContact)
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.parse("tg://resolve?domain=RaldzzXyz");
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(Uri.parse("https://t.me/RaldzzXyz"),
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text(
                "Contact Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Fungsi untuk manual refresh base URL
  Future<void> _refreshBaseUrl() async {
    setState(() {
      _isLoadingConfig = true;
    });
    
    try {
      print('🔄 Manually refreshing base URL...');
      final apiConfig = ApiConfigService();
      final newUrl = await apiConfig.forceRefresh();
      
      if (newUrl.isNotEmpty) {
        setState(() {
          _baseUrl = newUrl;
          _isLoadingConfig = false;
        });
        print('✅ Base URL refreshed: $_baseUrl');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Server configuration updated',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Base URL is empty after refresh');
      }
    } catch (e) {
      print('❌ Failed to refresh base URL: $e');
      setState(() {
        _isLoadingConfig = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update server configuration'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
                  CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading server configuration...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_retryCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Retry $_retryCount/3',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                      ),
                    ),
                ],
              ),
            )
          : Stack(
              children: [
                // Background video
                SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: _videoController.value.isInitialized
                        ? SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          )
                        : Container(color: Colors.black),
                  ),
                ),
                // Dark overlay for better readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Login form
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Image.asset(
                              'assets/images/logo.png',
                              height: 140,
                              width: 140,
                            ),
                            const SizedBox(height: 20),

                            // App Title - XCUBE APPS
                            const Text(
                              "XCUBE APPS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Login form container with blur effect
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Username field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: TextField(
                                          controller: userController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'ShareTechMono',
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: Colors.white.withOpacity(0.6),
                                              size: 22,
                                            ),
                                            hintText: "Username",
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontFamily: 'ShareTechMono',
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.blue.withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Password field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: TextField(
                                          controller: passController,
                                          obscureText: true,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'ShareTechMono',
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                              color: Colors.white.withOpacity(0.6),
                                              size: 22,
                                            ),
                                            hintText: "Password",
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontFamily: 'ShareTechMono',
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.blue.withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),

                                      // Access Gateway Button (Blue)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: isLoading || _baseUrl == null ? null : login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            elevation: 5,
                                            shadowColor: Colors.blue.withOpacity(0.5),
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  "Access Gateway",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                    fontFamily: 'Orbitron',
                                                  ),
                                                ),
                                        ),
                                      ),
                                      
                                      // Optional: Show server URL indicator (tap to refresh)
                                      const SizedBox(height: 12),
                                      if (_baseUrl != null)
                                        GestureDetector(
                                          onTap: _refreshBaseUrl,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.cloud_queue,
                                                  size: 12,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Server: ${_baseUrl!.replaceAll(RegExp(r'https?://'), '').substring(0, 20)}...',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 9,
                                                    fontFamily: 'ShareTechMono',
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.refresh,
                                                  size: 10,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ),
                                          ),
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
                  ),
                ),
              ],
            ),
    );
  }
}