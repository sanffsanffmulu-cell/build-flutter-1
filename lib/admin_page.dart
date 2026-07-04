import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['vip', 'reseller', 'reseller1', 'owner', 'member'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  // 🎨 PALETTE BIRU
  final Color primaryDark = const Color(0xFF0A1929);
  final Color primaryBlue = const Color(0xFF2B4F8C);
  final Color accentBlue = const Color(0xFF1E3A6F);
  final Color lightBlue = const Color(0xFF4A7DB5);
  final Color softWhite = const Color(0xFFF0F4FA);
  final Color cardBlue = const Color(0xFF13263E);
  final Color tealAccent = const Color(0xFF1B9C9C);
  final Color cyanLight = const Color(0xFF4ECDC4);
  final Color royalBlue = const Color(0xFF4169E1);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://fakz.cyberpanel.web.id:3003/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showDialog("⚠️ Error", data['message'] ?? 'Tidak diizinkan melihat daftar user.');
      }
    } catch (_) {
      _showDialog("🌐 Error", "Gagal memuat user list.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _showDialog("⚠️ Error", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://fakz.cyberpanel.web.id:3003/deleteUser?key=$sessionKey&username=$username'),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showDialog("✅ Berhasil", "User '${data['user']['username']}' telah dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _showDialog("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _showDialog("🌐 Error", "Tidak dapat menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showDialog("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://fakz.cyberpanel.web.id:3003/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showDialog("✅ Sukses", "Akun '${data['user']['username']}' berhasil dibuat.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _showDialog("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _showDialog("🌐 Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tealAccent.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(
              title.contains("✅") ? Icons.check_circle :
              title.contains("❌") ? Icons.error :
              title.contains("⚠️") ? Icons.warning :
              Icons.info,
              color: title.contains("✅") ? cyanLight :
              title.contains("❌") ? tealAccent :
              title.contains("⚠️") ? Colors.orange : primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: softWhite)),
          ],
        ),
        content: Text(message, style: TextStyle(color: softWhite.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cyanLight.withOpacity(0.3)),
              ),
              child: Text("OK", style: TextStyle(color: cyanLight)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Card(
      color: cardBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tealAccent.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 4,
      shadowColor: primaryBlue.withOpacity(0.2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          user['username'],
          style: TextStyle(
            color: softWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Role: ${user['role']} | Exp: ${user['expiredDate']}",
              style: TextStyle(color: softWhite.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              "Parent: ${user['parent'] ?? 'SYSTEM'}",
              style: TextStyle(color: softWhite, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: tealAccent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: cyanLight.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: cardBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: tealAccent.withOpacity(0.3)),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text("Konfirmasi", style: TextStyle(color: softWhite)),
                    ],
                  ),
                  content: Text(
                    "Yakin ingin menghapus user '${user['username']}'?",
                    style: TextStyle(color: softWhite.withOpacity(0.7)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: softWhite.withOpacity(0.3)),
                        ),
                        child: Text("Batal", style: TextStyle(color: softWhite.withOpacity(0.7))),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: tealAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cyanLight.withOpacity(0.3)),
                        ),
                        child: Text("Hapus", style: TextStyle(color: cyanLight)),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                deleteController.text = user['username'];
                _deleteUser();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page ? primaryBlue : cardBlue,
            foregroundColor: currentPage == page ? softWhite : softWhite.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: cyanLight.withOpacity(0.3)),
            ),
          ),
          child: Text("$page"),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "Admin Panel",
          style: TextStyle(
            color: softWhite,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            shadows: [
              Shadow(
                color: cyanLight.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        iconTheme: IconThemeData(color: softWhite),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cyanLight.withOpacity(0.3),
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Delete User Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyanLight.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, cyanLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, color: softWhite, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "DELETE USER",
                          style: TextStyle(
                            color: softWhite,
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deleteController,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Username untuk dihapus"),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: cyanLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _deleteUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: softWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Create Account Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyanLight.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, cyanLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add, color: softWhite, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "CREATE ACCOUNT",
                          style: TextStyle(
                            color: softWhite,
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: createUsernameController,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Username"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: createPasswordController,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Password"),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: createDayController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Durasi (hari)"),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: newUserRole,
                    dropdownColor: cardBlue,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Role"),
                    items: roleOptions.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: cyanLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: softWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, size: 18),
                          SizedBox(width: 8),
                          Text("CREATE", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User List Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyanLight.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, cyanLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, color: softWhite, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "USER MANAGEMENT",
                          style: TextStyle(
                            color: softWhite,
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: cardBlue,
                    style: TextStyle(color: softWhite),
                    decoration: _inputDecoration("Filter Role"),
                    items: roleOptions.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedRole = val;
                        _filterAndPaginate();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: cyanLight),
                        )
                      : Column(
                          children: [
                            ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                            const SizedBox(height: 16),
                            _buildPagination(),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: softWhite.withOpacity(0.7)),
      filled: true,
      fillColor: primaryDark.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cyanLight.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cyanLight, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}