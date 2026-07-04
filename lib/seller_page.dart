import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_config_service.dart';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with TickerProviderStateMixin {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

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

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  // --- API Logic dengan ApiConfigService ---
  Future<void> _create() async {
    final u = _newUser.text.trim();
    final p = _newPass.text.trim();
    final d = _days.text.trim();
    
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _showNotification("Semua field wajib diisi", isError: true);
      return;
    }

    // Validasi durasi harus angka
    if (int.tryParse(d) == null) {
      _showNotification("Durasi harus berupa angka", isError: true);
      return;
    }

    setState(() {
      loading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/user/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d");
      
      print('🌐 Creating account: $url');
      
      final res = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['created'] == true) {
          _showNotification("✅ Akun berhasil dibuat!");
          _newUser.clear(); 
          _newPass.clear(); 
          _days.clear();
          Navigator.pop(context); // Tutup dialog setelah sukses
        } else {
          _showNotification(data['message'] ?? 'Gagal membuat akun.', isError: true);
        }
      } else {
        throw Exception('HTTP Error ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating account: $e');
      
      setState(() {
        _errorMessage = e.toString();
      });
      
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
      
      // Coba refresh base URL jika gagal
      try {
        await ApiConfig.refresh();
        _showNotification("Base URL telah diperbarui. Silakan coba lagi.", isError: false);
      } catch (refreshError) {
        // Ignore refresh error
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim();
    final d = _editDays.text.trim();
    
    if (u.isEmpty || d.isEmpty) {
      _showNotification("Username dan durasi wajib diisi", isError: true);
      return;
    }

    // Validasi durasi harus angka
    if (int.tryParse(d) == null) {
      _showNotification("Durasi harus berupa angka", isError: true);
      return;
    }

    setState(() {
      loading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/user/editUser?key=${widget.keyToken}&username=$u&addDays=$d");
      
      print('🌐 Editing account: $url');
      
      final res = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['edited'] == true) {
          _showNotification("✅ Durasi berhasil diperbarui.");
          _editUser.clear(); 
          _editDays.clear();
          Navigator.pop(context); // Tutup dialog setelah sukses
        } else {
          _showNotification(data['message'] ?? 'Gagal mengubah durasi.', isError: true);
        }
      } else {
        throw Exception('HTTP Error ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error editing account: $e');
      
      setState(() {
        _errorMessage = e.toString();
      });
      
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
      
      // Coba refresh base URL jika gagal
      try {
        await ApiConfig.refresh();
        _showNotification("Base URL telah diperbarui. Silakan coba lagi.", isError: false);
      } catch (refreshError) {
        // Ignore refresh error
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _refreshBaseUrl() async {
    setState(() => loading = true);

    try {
      final newUrl = await ApiConfig.refresh();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Base URL updated: $newUrl',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2196F3),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      _showNotification("Failed to refresh URL: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, 
              size: 20
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade900 : const Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- UI Widgets ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _mainActionButton("Buat Akun Baru", Icons.person_add, _showCreateAccountDialog),
                const SizedBox(height: 20),
                _mainActionButton("Ubah Durasi Akun", Icons.edit_calendar, _showEditDurationDialog),
                const SizedBox(height: 40),
                _buildLastUpdateInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Reseller Panel",
        style: TextStyle(
          color: Color(0xFF2196F3),
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
      actions: [
        // Refresh URL button
        IconButton(
          icon: const Icon(Icons.sync, color: Color(0xFF2196F3)),
          onPressed: loading ? null : _refreshBaseUrl,
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
                    color: const Color(0xFF2196F3).withOpacity(0.5),
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
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1 + 0.1 * _glowAnimation.value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3 + 0.2 * _glowAnimation.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Color(0xFF2196F3),
                size: 40,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          "Reseller Management",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Create and manage user accounts",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  Widget _mainActionButton(String title, IconData icon, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.02 * _glowAnimation.value),
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(loading ? 0.1 : 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.1 * _glowAnimation.value),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    color: loading 
                        ? const Color(0xFF2196F3).withOpacity(0.3)
                        : const Color(0xFF2196F3), 
                    size: 28
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title, 
                    style: TextStyle(
                      color: loading 
                          ? const Color(0xFF2196F3).withOpacity(0.3)
                          : const Color(0xFF2196F3), 
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastUpdateInfo() {
    return FutureBuilder<DateTime?>(
      future: ApiConfigService().getLastUpdateTime(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
          ),
          child: Text(
            'Config updated: ${_formatDate(snapshot.data!)}',
            style: TextStyle(
              color: const Color(0xFF2196F3).withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'ShareTechMono',
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

  // --- Dialogs ---
  void _showCreateAccountDialog() {
    _newUser.clear();
    _newPass.clear();
    _days.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: "Buat Akun Baru",
        icon: Icons.person_add,
        fields: [
          _inputField("Username", _newUser),
          _inputField("Password", _newPass, obscure: true),
          _inputField("Durasi (hari)", _days, type: TextInputType.number),
        ],
        onConfirm: _create,
      ),
    );
  }

  void _showEditDurationDialog() {
    _editUser.clear();
    _editDays.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: "Ubah Durasi Akun",
        icon: Icons.edit_calendar,
        fields: [
          _inputField("Username", _editUser),
          _inputField("Tambah Durasi (hari)", _editDays, type: TextInputType.number),
        ],
        onConfirm: _edit,
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required IconData icon,
    required List<Widget> fields,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all( // INI YANG DIPERBAIKI - Menggunakan Border.all
            color: const Color(0xFF2196F3).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF2196F3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title, 
                    style: const TextStyle(
                      color: Color(0xFF2196F3), 
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...fields,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text(
                      "BATAL",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: loading ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 80,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : const Text(
                            "KONFIRMASI",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label, 
    TextEditingController c, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(
              color: Color(0xFF2196F3), 
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: type,
            obscureText: obscure,
            style: const TextStyle(color: Color(0xFF2196F3)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), 
                borderSide: BorderSide.none
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2196F3), 
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }
}