import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage> {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  // 🎨 PALETTE BIRU
  final Color primaryDark = const Color(0xFF0A1929);
  final Color primaryBlue = const Color(0xFF2B4F8C);
  final Color accentBlue = const Color(0xFF1E3A6F);
  final Color lightBlue = const Color(0xFF4A7DB5);
  final Color softWhite = const Color(0xFFF0F4FA);
  final Color cardBlue = const Color(0xFF13263E);
  final Color tealAccent = const Color(0xFF1B9C9C);
  final Color cyanLight = const Color(0xFF4ECDC4);
  final Color successGreen = Colors.greenAccent;
  final Color warningOrange = Colors.orangeAccent;
  final Color errorRed = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _fetchSenders();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://fakz.cyberpanel.web.id:3003/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            senderList = data["connections"] ?? [];
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Failed to fetch senders";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection failed: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
  }

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: cyanLight),
            const SizedBox(width: 12),
            Text("Add New Sender",
                style: TextStyle(color: softWhite, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: softWhite),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: cyanLight),
                hintText: "62xxx",
                hintStyle: TextStyle(color: softWhite.withOpacity(0.5)),
                prefixIcon: Icon(Icons.phone, color: cyanLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cyanLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cyanLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: errorRed)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final number = phoneController.text.trim();
              final name = nameController.text.trim();

              if (number.isEmpty) {
                _showSnackBar("Please enter phone number", isError: true);
                return;
              }

              Navigator.pop(context);
              await _addSender(number, name);
            },
            child: Text("ADD SENDER", style: TextStyle(color: softWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _addSender(String number, String name) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("http://fakz.cyberpanel.web.id:3003/getPairing?key=${widget.sessionKey}&number=$number"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode'], name);
          _showSnackBar("Pairing code generated successfully!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Failed to generate pairing code", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.qr_code_2, color: cyanLight, size: 50),
            const SizedBox(height: 10),
            Text("Pairing Required",
                style: TextStyle(color: softWhite, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cyanLight.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name.isNotEmpty) ...[
                Text("Name: $name",
                    style: TextStyle(color: softWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              Text("Number: $number", style: TextStyle(color: softWhite)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cyanLight),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: cyanLight,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Open WhatsApp → Settings → Linked Devices → Link a Device\nEnter this code to complete pairing",
                textAlign: TextAlign.center,
                style: TextStyle(color: softWhite.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: TextStyle(color: softWhite)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              Navigator.pop(context);
              _fetchSenders();
            },
            child: Text("REFRESH LIST", style: TextStyle(color: softWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: warningOrange),
            const SizedBox(width: 12),
            Text("Confirm Delete", style: TextStyle(color: softWhite)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this sender? This action cannot be undone.",
          style: TextStyle(color: softWhite.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: softWhite.withOpacity(0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text("DELETE", style: TextStyle(color: softWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);

      try {
        final response = await http.delete(
          Uri.parse("http://fakz.cyberpanel.web.id:3003/deleteSender?key=${widget.sessionKey}&id=$senderId"),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Sender deleted successfully!", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(data["message"] ?? "Failed to delete sender", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? errorRed : cyanLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender['sessionName'] ?? 'Unnamed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryDark.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_android, color: cyanLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: softWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cyanLight,
                      side: BorderSide(color: cyanLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _refreshSenders(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete, size: 16),
                    label: Text("DELETE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorRed.withOpacity(0.2),
                      foregroundColor: errorRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _deleteSender(sender['id']),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_iphone, color: cyanLight, size: 80),
          const SizedBox(height: 20),
          Text(
            "No Senders Found",
            style: TextStyle(color: softWhite, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Add your first WhatsApp sender to get started",
            style: TextStyle(color: softWhite.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text("ADD FIRST SENDER"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showAddSenderDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: errorRed, size: 80),
          const SizedBox(height: 20),
          Text(
            "Failed to Load",
            style: TextStyle(color: softWhite, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? "Unknown error occurred",
            style: TextStyle(color: softWhite.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text("TRY AGAIN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            onPressed: _fetchSenders,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          "Manage Bug Sender",
          style: TextStyle(
            color: softWhite,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: softWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: cyanLight),
            onPressed: isLoading ? null : _refreshSenders,
          ),
        ],
      ),
      body: isLoading && senderList.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
          : errorMessage != null && senderList.isEmpty
          ? _buildErrorState()
          : senderList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: cyanLight,
              backgroundColor: cardBlue,
              onRefresh: _refreshSenders,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: senderList.length,
                itemBuilder: (context, index) => _buildSenderCard(
                  Map<String, dynamic>.from(senderList[index]),
                  index,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        onPressed: _showAddSenderDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}