import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_config_service.dart'; // Import ApiConfigService

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> with TickerProviderStateMixin {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  String? _errorMessage;
  
  // Warna biru gelap utama
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFF1E88E5);
  static const Color darkerBlue = Color(0xFF0A3A7A);
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    // Validasi input
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("All fields are required");
      return;
    }

    if (newPass.length < 6) {
      _showMessage("New password must be at least 6 characters");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("New password doesn't match confirmation");
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/user/changepass");
      
      print('🌐 Changing password at: $url');
      
      final res = await http.post(
        url,
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "key": widget.sessionKey,
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['success'] == true) {
          _showMessage("Password changed successfully", isSuccess: true);
          // Clear form after success
          oldPassCtrl.clear();
          newPassCtrl.clear();
          confirmPassCtrl.clear();
        } else {
          _showMessage(data['message'] ?? "Failed to change password");
        }
      } else {
        throw Exception('HTTP Error ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      
      // Coba refresh base URL jika gagal
      try {
        await ApiConfig.refresh();
        _showMessage("Connection issue. Base URL has been refreshed. Please try again.");
      } catch (refreshError) {
        setState(() {
          _errorMessage = e.toString();
        });
        _showMessage("Server error: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBaseUrl() async {
    setState(() {
      isLoading = true;
    });

    try {
      final newUrl = await ApiConfig.refresh();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base URL updated: $newUrl'),
          backgroundColor: darkBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh URL: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSuccess ? Colors.green : darkBlue,
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: isSuccess ? Colors.green : darkBlue,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              isSuccess ? "Success" : "Info",
              style: TextStyle(
                color: isSuccess ? Colors.greenAccent : darkBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'ShareTechMono',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: isSuccess ? Colors.green : darkBlue,
            ),
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  darkBlue.withOpacity(0.1),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        
                        const SizedBox(height: 30),
                        
                        // Form fields
                        _buildPasswordForm(),
                        
                        const SizedBox(height: 30),
                        
                        // Change password button
                        _buildChangeButton(),
                        
                        const SizedBox(height: 20),
                        
                        // Last update info
                        _buildLastUpdateInfo(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: darkBlue),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Change Password",
        style: TextStyle(
          color: darkBlue,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
      actions: [
        // Tombol refresh base URL
        IconButton(
          icon: const Icon(Icons.sync, color: darkBlue),
          onPressed: isLoading ? null : _refreshBaseUrl,
          tooltip: 'Refresh Base URL',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          alignment: Alignment.centerRight,
          child: FutureBuilder<DateTime?>(
            future: ApiConfigService().getLastUpdateTime(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'URL: ${_formatDate(snapshot.data!)}',
                  style: TextStyle(
                    color: darkBlue.withOpacity(0.5),
                    fontSize: 10,
                    fontFamily: 'ShareTechMono',
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkBlue.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: darkBlue.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.lock_outline,
              color: darkBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Change Password for ${widget.username}",
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'ShareTechMono',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildField(
            "Old Password", 
            oldPassCtrl, 
            icon: Icons.lock,
            obscure: true,
          ),
          const SizedBox(height: 20),
          _buildField(
            "New Password", 
            newPassCtrl, 
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 20),
          _buildField(
            "Confirm Password", 
            confirmPassCtrl, 
            icon: Icons.lock_clock,
            obscure: true,
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String hint, 
    TextEditingController controller, {
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'ShareTechMono',
          ),
          prefixIcon: Icon(icon, color: darkBlue),
          filled: true,
          fillColor: Colors.grey[900]?.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkBlue.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkBlue.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildChangeButton() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              darkBlue,
              accentBlue,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: darkBlue.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "PROCESSING...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Orbitron',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                )
              : const Text(
                  "CHANGE PASSWORD",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    return FutureBuilder<DateTime?>(
      future: ApiConfigService().getLastUpdateTime(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: darkBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: darkBlue.withOpacity(0.2)),
            ),
            child: Text(
              'Config updated: ${_formatDate(snapshot.data!)}',
              style: TextStyle(
                color: darkBlue.withOpacity(0.7),
                fontSize: 10,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }
}