import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;

  // 🎨 PALETTE BIRU
  final Color primaryDark = const Color(0xFF0A1929);
  final Color primaryBlue = const Color(0xFF2B4F8C);
  final Color accentBlue = const Color(0xFF1E3A6F);
  final Color lightBlue = const Color(0xFF4A7DB5);
  final Color softWhite = const Color(0xFFF0F4FA);
  final Color cardBlue = const Color(0xFF13263E);
  final Color tealAccent = const Color(0xFF1B9C9C);
  final Color cyanLight = const Color(0xFF4ECDC4);

  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) return _alert("❗ Semua field wajib diisi");
    setState(() => loading = true);
    final res = await http.get(Uri.parse(
        "https://yosh.nullxteam.fun/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
    final data = jsonDecode(res.body);
    if (data['created'] == true) {
      _alert("✅ Akun berhasil dibuat!");
      _newUser.clear(); _newPass.clear(); _days.clear();
    } else {
      _alert("❌ ${data['message'] ?? 'Gagal membuat akun.'}");
    }
    setState(() => loading = false);
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) return _alert("❗ Username dan durasi wajib diisi");
    setState(() => loading = true);
    final res = await http.get(Uri.parse(
        "https://yosh.nullxteam.fun/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
    final data = jsonDecode(res.body);
    if (data['edited'] == true) {
      _alert("✅ Durasi berhasil diperbarui.");
      _editUser.clear(); _editDays.clear();
    } else {
      _alert("❌ ${data['message'] ?? 'Gagal mengubah durasi.'}");
    }
    setState(() => loading = false);
  }

  void _alert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: cyanLight.withOpacity(0.3)),
        ),
        content: Text(msg, style: TextStyle(color: softWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: cyanLight)),
          )
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        style: TextStyle(color: softWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cyanLight),
          filled: true,
          fillColor: cardBlue,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cyanLight.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cyanLight),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(
        color: softWhite, fontSize: 16, fontFamily: 'Orbitron', fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: cyanLight.withOpacity(0.5),
            blurRadius: 5,
          )
        ])),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryDark,
        body: Container(
          color: primaryDark,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle("Buat Akun Baru"),
                _input("Username", _newUser),
                _input("Password", _newPass),
                _input("Durasi (hari)", _days, type: TextInputType.number),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [primaryBlue, cyanLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyanLight.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: softWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: loading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: softWhite,
                      ),
                    )
                        : const Text("BUAT", style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
                _sectionTitle("Ubah Durasi"),
                _input("Username", _editUser),
                _input("Tambah Durasi (hari)", _editDays, type: TextInputType.number),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [primaryBlue, cyanLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyanLight.withOpacity(0.5),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : _edit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: softWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: loading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: softWhite,
                      ),
                    )
                        : const Text("UBAH", style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}