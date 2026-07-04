import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class SplashPage extends StatefulWidget {
  final String? username;
  final String? password;
  final String? role;
  final String? sessionKey;
  final String? expiredDate;
  final List<Map<String, dynamic>>? listBug;
  final List<Map<String, dynamic>>? listPayload;
  final List<Map<String, dynamic>>? listDDoS;
  final List<Map<String, dynamic>>? news;

  const SplashPage({
    super.key,
    this.username,
    this.password,
    this.role,
    this.sessionKey,
    this.expiredDate,
    this.listBug,
    this.listPayload,
    this.listDDoS,
    this.news,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Warna biru cerah
  final Color brightBlue = const Color(0xFF00B4FF);
  final Color electricBlue = const Color(0xFF00E0FF);
  final Color cyanBlue = const Color(0xFF00D4FF);
  final Color darkBlue = const Color(0xFF001F3F);
  final Color lightBlue = const Color(0xFFB0E0FF);
  final Color accentBlue = const Color(0xFF1E90FF);
  
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/videos/r.mp4")
      ..initialize().then((_) {
        final videoDuration = _controller.value.duration;
        
        _progressController = AnimationController(
          duration: videoDuration,
          vsync: this,
        );

        _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.linear),
        );

        setState(() {
          _isVideoInitialized = true;
        });
        
        _progressController.forward();
        _controller.play();
      }).catchError((error) {
        print("Error loading video: $error");
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _navigateToDashboard();
          }
        });
      });

    _controller.setLooping(false);
    _controller.addListener(() {
      if (_controller.value.isInitialized && _controller.value.isPlaying) {
        final progress = _controller.value.position.inMilliseconds / 
                        _controller.value.duration.inMilliseconds;
        if (_progressController.value != progress && progress <= 1.0) {
          _progressController.value = progress;
        }
      }

      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(
      context,
      '/loader',
      arguments: {
        'username': widget.username,
        'password': widget.password,
        'role': widget.role,
        'key': widget.sessionKey,
        'expiredDate': widget.expiredDate,
        'listBug': widget.listBug ?? [],
        'listPayload': widget.listPayload ?? [],
        'listDDoS': widget.listDDoS ?? [],
        'news': widget.news ?? [],
      },
    );
  }

  void _skipVideo() {
    _navigateToDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: Stack(
        children: [
          // Video Full Screen
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Container(
              color: darkBlue,
              child: Center(
                child: CircularProgressIndicator(
                  color: brightBlue,
                ),
              ),
            ),

          // Gradient overlay with blue tones
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  darkBlue.withOpacity(0.5),
                  darkBlue.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // TOMBOL SKIP DI POJOK KANAN ATAS
          Positioned(
            top: 50,
            right: 20,
            child: _isVideoInitialized
                ? GestureDetector(
                    onTap: _skipVideo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: lightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: brightBlue.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SKIP",
                            style: TextStyle(
                              color: lightBlue,
                              fontSize: 14,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.skip_next_rounded,
                            color: lightBlue,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
          ),

          // CONTENT DI BAWAH
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Progress bar
                Center(
                  child: SizedBox(
                    width: 220,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value,
                          color: electricBlue,
                          backgroundColor: brightBlue.withOpacity(0.3),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // XCUBE (di bawah) with blue gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [lightBlue, brightBlue, electricBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "XCUBE",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Username (di bawah XCUBE)
                if (widget.username != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: brightBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: brightBlue.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Welcome, ${widget.username}",
                      style: TextStyle(
                        color: lightBlue,
                        fontSize: 16,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}