import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_config_service.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // --- State Variables ---
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['vip', 'reseller', 'reseller1', 'owner', 'member'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 50;
  bool isLoading = false;
  String? _baseUrlError;

  // --- Controllers ---
  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  @override
  void dispose() {
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  // --- API Logic dengan ApiConfigService ---
  Future<void> _fetchUsers() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      _baseUrlError = null;
    });
    
    try {
      // Gunakan ApiConfig untuk mendapatkan base URL
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/user/listUsers?key=$sessionKey');
      
      print('🌐 Fetching users from: $url');
      
      final res = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Koneksi timeout - server tidak merespon');
        },
      );
      
      print('📥 Response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['authorized'] == true) {
          setState(() {
            fullUserList = data['users'] ?? [];
          });
          _filterAndPaginate();
          _showSnackBar('✅ Data berhasil dimuat (${data['users']?.length ?? 0} users)');
        } else {
          _showSnackBar(data['message'] ?? 'Tidak diizinkan melihat daftar user.', isError: true);
        }
      } else {
        throw Exception('HTTP Error ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      
      // Coba refresh base URL jika gagal
      try {
        final newBaseUrl = await ApiConfig.refresh();
        _showSnackBar('Base URL diperbarui: $newBaseUrl', isError: false);
        
        // Coba lagi dengan URL baru
        await _retryFetchUsers();
      } catch (refreshError) {
        setState(() {
          _baseUrlError = 'Gagal mendapatkan konfigurasi server. Periksa koneksi internet.';
        });
        _showSnackBar("Gagal memuat user list: ${e.toString()}", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _retryFetchUsers() async {
    try {
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/user/listUsers?key=$sessionKey');
      
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['authorized'] == true) {
          setState(() {
            fullUserList = data['users'] ?? [];
            _baseUrlError = null;
          });
          _filterAndPaginate();
        }
      }
    } catch (e) {
      print('❌ Retry failed: $e');
    }
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser(String username) async {
    setState(() => isLoading = true);
    
    try {
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/user/deleteUser?key=$sessionKey&username=$username');
      
      print('🗑️ Deleting user: $username');
      
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      
      if (data['deleted'] == true) {
        _showSnackBar("User '${data['user']['username']}' telah dihapus.");
        _fetchUsers(); // Refresh list
      } else {
        _showSnackBar(data['message'] ?? 'Gagal menghapus user.', isError: true);
      }
    } catch (e) {
      print('❌ Error deleting user: $e');
      _showSnackBar("Tidak dapat menghubungi server: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showSnackBar("Semua field wajib diisi.", isError: true);
      return;
    }

    // Validasi angka untuk day
    if (int.tryParse(day) == null) {
      _showSnackBar("Duration harus berupa angka.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    Navigator.pop(context); // Tutup dialog

    try {
      final baseUrl = await ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/api/user/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole');
      
      print('➕ Creating user: $username');
      
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showSnackBar("Akun '${data['user']['username']}' berhasil dibuat.");
        _fetchUsers(); // Refresh list
      } else {
        _showSnackBar(data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (e) {
      print('❌ Error creating user: $e');
      _showSnackBar("Gagal menghubungi server: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshBaseUrl() async {
    setState(() => isLoading = true);
    
    try {
      final newUrl = await ApiConfig.refresh();
      _showSnackBar('Base URL diperbarui: $newUrl');
      
      // Tampilkan info last update
      final lastUpdate = await ApiConfigService().getLastUpdateTime();
      if (lastUpdate != null) {
        print('🕒 Last update: $lastUpdate');
      }
      
      // Refresh data dengan URL baru
      await _fetchUsers();
    } catch (e) {
      _showSnackBar('Gagal refresh URL: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade900 : Colors.grey.shade800,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
          : _baseUrlError != null
              ? _buildErrorView()
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildActionCards(),
                      const SizedBox(height: 24),
                      _buildFilterChips(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildUserTable()),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Admin Panel',
        style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
      ),
      actions: [
        // Tombol refresh manual
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2196F3)),
          onPressed: isLoading ? null : _fetchUsers,
          tooltip: 'Refresh Data',
        ),
        // Tombol refresh base URL
        IconButton(
          icon: const Icon(Icons.sync, color: Color(0xFF2196F3)),
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
                  'URL updated: ${_formatDate(snapshot.data!)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: TextStyle(color: Colors.grey[300], fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _baseUrlError ?? 'Gagal terhubung ke server',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshBaseUrl,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            title: 'Create User',
            icon: Icons.person_add,
            onTap: () => _showCreateUserDialog(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard(
            title: 'Delete User',
            icon: Icons.person_remove,
            onTap: () => _showDeleteUserDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 32),
            const SizedBox(height: 12),
            Text(
              title, 
              style: const TextStyle(color: Color(0xFF2196F3), fontSize: 16, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8.0,
      children: roleOptions.map((role) {
        final isSelected = selectedRole == role;
        return FilterChip(
          label: Text(role.toUpperCase()),
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF2196F3),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          selected: isSelected,
          onSelected: (isSelected) {
            setState(() {
              selectedRole = role;
              _filterAndPaginate();
            });
          },
          backgroundColor: Colors.grey[800],
          selectedColor: const Color(0xFF2196F3),
          checkmarkColor: Colors.black,
          side: BorderSide(color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade600),
        );
      }).toList(),
    );
  }

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), 
                topRight: Radius.circular(12)
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'USERNAME',
                    style: TextStyle(color: const Color(0xFF2196F3), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ROLE',
                    style: TextStyle(color: const Color(0xFF2196F3), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PARENT',
                    style: TextStyle(color: const Color(0xFF2196F3), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40), // Space for action
              ],
            ),
          ),
          
          // List Users
          _buildCompactListView(),
          
          // Pagination
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildCompactListView() {
    if (filteredList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No users found for this role.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 400, // Fixed height for scrolling
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _getCurrentPageData().length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade700,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = _getCurrentPageData()[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Username
                Expanded(
                  flex: 2,
                  child: Text(
                    user['username'] ?? 'N/A',
                    style: const TextStyle(color: Color(0xFF2196F3), fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Role with color badge
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user['role'] ?? 'member'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['role']?.toString().toUpperCase() ?? 'MEMBER',
                      style: const TextStyle(
                        color: Colors.black, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Parent/Expires
                Expanded(
                  flex: 2,
                  child: Text(
                    user['parent'] ?? 'SYSTEM',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Action Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF2196F3), size: 20),
                  onPressed: () => _showDeleteConfirmationDialog(user['username']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'vip':
        return Colors.amber.shade300;
      case 'reseller':
        return Colors.blue.shade300;
      case 'reseller1':
        return Colors.lightBlue.shade300;
      case 'owner':
        return Colors.purple.shade300;
      case 'member':
        return Colors.green.shade300;
      default:
        return const Color(0xFF2196F3).withOpacity(0.5);
    }
  }

  Widget _buildPaginationControls() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF2196F3)),
            onPressed: currentPage > 1 
                ? () {
                    setState(() => currentPage--);
                    _scrollToTop();
                  } 
                : null,
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF2196F3)),
            onPressed: currentPage < totalPages 
                ? () {
                    setState(() => currentPage++);
                    _scrollToTop();
                  } 
                : null,
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    // Optional: scroll list to top when changing page
  }

  // --- Dialogs ---
  void _showCreateUserDialog() {
    createUsernameController.clear();
    createPasswordController.clear();
    createDayController.clear();
    newUserRole = 'member';

    showDialog(
      context: context,
      builder: (_) => _buildCreateUserDialog(),
    );
  }

  Widget _buildCreateUserDialog() {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create New User',
              style: TextStyle(
                color: Color(0xFF2196F3), 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: createUsernameController, 
              label: 'Username',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: createPasswordController, 
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: createDayController, 
              label: 'Duration (days)', 
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: newUserRole,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Color(0xFF2196F3)),
              decoration: _inputDecoration('Role', Icons.security),
              items: roleOptions.map((role) {
                return DropdownMenuItem(
                  value: role, 
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3), 
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Create'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog() {
    deleteController.clear();
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete User',
                style: TextStyle(
                  color: Color(0xFF2196F3), 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: deleteController, 
                label: 'Username to delete',
                icon: Icons.person_remove,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteUser(deleteController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Confirm Delete', 
          style: TextStyle(color: Color(0xFF2196F3))
        ),
        content: Text(
          'Are you sure you want to delete user "$username"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(username);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2196F3)),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: const Color(0xFF2196F3).withOpacity(0.7)),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2196F3)) : null,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2196F3)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.grey[850],
    );
  }
}