import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  bool _fadeOutStarted = false;
  double _videoProgress = 0.0;
  bool _isNavigating = false;
  Timer? _videoTimeoutTimer;

  // 🎨 PALETTE BIRU - Oceanic Blue
  final Color primaryDark = const Color(0xFF0A1929);      // Dark navy blue
  final Color primaryBlue = const Color(0xFF2B4F8C);      // Medium blue
  final Color accentBlue = const Color(0xFF1E3A6F);       // Dark blue accent
  final Color lightBlue = const Color(0xFF4A7DB5);        // Light blue
  final Color softWhite = const Color(0xFFF0F4FA);        // Soft white with blue tint
  final Color cardBlue = const Color(0xFF13263E);         // Card background blue
  final Color tealAccent = const Color(0xFF1B9C9C);       // Teal accent
  final Color cyanLight = const Color(0xFF4ECDC4);        // Cyan light
  final Color royalBlue = const Color(0xFF4169E1);        // Royal blue

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _videoTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!_isNavigating) {
        _skipIntro();
      }
    });

    _videoController = VideoPlayerController.asset("assets/videos/banner.mp4")
      ..initialize().then((_) {
        _videoTimeoutTimer?.cancel();
        setState(() {});
        _videoController.setLooping(false);
        _videoController.play();

        _videoController.addListener(() {
          if (_videoController.value.isInitialized) {
            final position = _videoController.value.position;
            final duration = _videoController.value.duration;

            if (duration != null) {
              setState(() {
                _videoProgress = position.inMilliseconds / duration.inMilliseconds;
              });
            }

            if (duration != null &&
                position >= duration - const Duration(seconds: 1) &&
                !_fadeOutStarted) {
              _fadeOutStarted = true;
              _fadeController.forward().then((_) {
                _navigateToDashboard();
              });
            }

            if (position >= duration && !_isNavigating) {
              _navigateToDashboard();
            }
          }
        });
      }).catchError((error) {
        print("Error loading video: $error");
        _videoTimeoutTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isNavigating) {
            _skipIntro();
          }
        });
      });
  }

  void _navigateToDashboard() {
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
          news: widget.news,
        ),
      ),
    );
  }

  void _skipIntro() {
    if (_isNavigating) return;

    _videoTimeoutTimer?.cancel();
    _isNavigating = true;
    _fadeOutStarted = true;

    if (_videoController.value.isInitialized) {
      _videoController.pause();
    }

    _fadeController.forward().then((_) {
      _navigateToDashboard();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _videoTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: GestureDetector(
        onTap: _skipIntro,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video atau indikator loading dengan efek biru
            if (_videoController.value.isInitialized)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        color: softWhite.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: cyanLight.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cyanLight.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                ),
              )
            else
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(cyanLight),
                ),
              ),

            // Teks, Loading Bar, dan Tombol Skip
            Positioned(
              bottom: 80,
              child: Column(
                children: [
                  Text(
                    "Yoshimitsu",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: softWhite,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: cyanLight.withOpacity(0.9),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                        Shadow(
                          color: primaryDark.withOpacity(0.8),
                          blurRadius: 15,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Loading Bar dengan warna biru
                  Container(
                    width: 200,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: softWhite.withOpacity(0.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _videoProgress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cyanLight.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tombol Skip dengan gradient biru
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, cyanLight, tealAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cyanLight.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _skipIntro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: softWhite,
                        side: BorderSide(color: softWhite.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        "Lewati Intro",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: primaryDark.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fade out effect dengan warna biru gelap
            if (_fadeOutStarted)
              FadeTransition(
                opacity: _fadeController.drive(Tween(begin: 1.0, end: 0.0)),
                child: Container(color: primaryDark),
              ),
          ],
        ),
      ),
    );
  }
}