// manage_server_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/api_config_service.dart';

class ManageServerPage extends StatefulWidget {
  final String sessionKey;

  const ManageServerPage({super.key, required this.sessionKey});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> with TickerProviderStateMixin {
  // Hapus baseUrl statis
  static const Color primaryColor = Color(0xFF8BC34A); // Light green
  static const Color secondaryColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFF00E676); // Bright green

  bool _isLoading = true;
  List<Map<String, dynamic>> _servers = [];
  String? _errorMessage;

  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchServers();
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

  Future<void> _fetchServers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/vps/myServer?key=${widget.sessionKey}");
      
      print('🌐 Fetching servers from: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['servers'] != null) {
          setState(() {
            _servers = List<Map<String, dynamic>>.from(data['servers']);
          });
        } else {
          setState(() {
            _servers = [];
          });
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching servers: $e');
      
      setState(() {
        _errorMessage = e.toString();
      });
      
      _showMessage("Error fetching servers: ${e.toString()}", isError: true);
      
      // Coba refresh base URL jika gagal
      try {
        await ApiConfig.refresh();
        _showMessage("Base URL has been refreshed. Pull down to retry.", isError: false);
      } catch (refreshError) {
        // Ignore refresh error
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addServer() async {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage("All fields are required.", isError: true);
      return;
    }

    // Validasi format host (IP atau domain)
    final hostRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!hostRegex.hasMatch(host)) {
      _showMessage("Invalid host format.", isError: true);
      return;
    }

    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/vps/addServer");
      
      print('🌐 Adding server to: $url');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
          "username": username,
          "password": password,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showMessage("✅ Server added successfully!");
          _hostController.clear();
          _usernameController.clear();
          _passwordController.clear();
          Navigator.pop(context); // Close dialog
          _fetchServers(); // Refresh list
        } else {
          _showMessage(data['error'] ?? "Failed to add server.", isError: true);
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error adding server: $e');
      _showMessage("Error adding server: ${e.toString()}", isError: true);
    }
  }

  Future<void> _deleteServer(String host) async {
    try {
      // Gunakan ApiConfigService untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/api/vps/delServer");
      
      print('🗑️ Deleting server: $host from $url');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Server not responding.');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showMessage("✅ Server deleted successfully!");
          _fetchServers(); // Refresh list
        } else {
          _showMessage(data['error'] ?? "Failed to delete server.", isError: true);
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting server: $e');
      _showMessage("Error deleting server: ${e.toString()}", isError: true);
    }
  }

  Future<void> _refreshBaseUrl() async {
    setState(() => _isLoading = true);

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
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      // Refresh data after URL update
      await _fetchServers();
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddServerDialog() {
    _hostController.clear();
    _usernameController.clear();
    _passwordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        title: const Text(
          "Add New Server", 
          style: TextStyle(color: primaryColor, fontFamily: 'Orbitron')
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: _hostController,
              hint: "Host IP",
              icon: Icons.dns,
            ),
            const SizedBox(height: 12),
            _buildDialogField(
              controller: _usernameController,
              hint: "SSH Username",
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildDialogField(
              controller: _passwordController,
              hint: "SSH Password",
              icon: Icons.lock,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: _addServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor, 
              foregroundColor: Colors.black,
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: primaryColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: primaryColor, size: 20),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade900 : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmation(String host) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        title: const Text(
          "Confirm Delete", 
          style: TextStyle(color: primaryColor, fontFamily: 'Orbitron')
        ),
        content: Text(
          "Are you sure you want to delete server $host?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteServer(host);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null && _servers.isEmpty
              ? _buildErrorView()
              : _servers.isEmpty
                  ? _buildEmptyView()
                  : _buildServersList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "Manage Servers",
        style: TextStyle(
          color: primaryColor,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: primaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: primaryColor),
          onPressed: _fetchServers,
          tooltip: 'Refresh Data',
        ),
        IconButton(
          icon: const Icon(Icons.sync, color: primaryColor),
          onPressed: _isLoading ? null : _refreshBaseUrl,
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
                    color: primaryColor.withOpacity(0.5),
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1 + 0.1 * _glowAnimation.value),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3 + 0.2 * _glowAnimation.value),
                    width: 2,
                  ),
                ),
                child: const CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            "Loading servers...",
            style: TextStyle(
              color: primaryColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "Error Loading Servers",
              style: TextStyle(
                color: Colors.red.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Unknown error occurred",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchServers,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1 + 0.1 * _glowAnimation.value),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3 + 0.2 * _glowAnimation.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.dns_outlined,
                    size: 64,
                    color: primaryColor.withOpacity(0.7),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              "No Servers Found",
              style: TextStyle(
                color: primaryColor.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first VPS server to get started",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddServerDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Server"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServersList() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchServers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _servers.length,
        itemBuilder: (context, index) {
          final server = _servers[index];
          return _buildServerCard(server, index);
        },
      ),
    );
  }

  Widget _buildServerCard(Map<String, dynamic> server, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.1),
              primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.computer,
              color: primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            server['host'] ?? 'Unknown Host',
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: primaryColor.withOpacity(0.5),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  server['username'] ?? 'N/A',
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            onPressed: () => _showDeleteConfirmation(server['host']),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * _glowAnimation.value),
          child: FloatingActionButton(
            onPressed: _showAddServerDialog,
            backgroundColor: accentColor,
            child: const Icon(
              Icons.add,
              color: Colors.black,
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
    _glowController.dispose();
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}