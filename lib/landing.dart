import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late VideoPlayerController _controller;
  late VideoPlayerController _backgroundController;

  // 🎨 PALETTE BIRU PREMIUM - Oceanic Blue
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

    _controller = VideoPlayerController.asset("assets/videos/landing.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });

    _backgroundController = VideoPlayerController.asset("assets/videos/landing.mp4")
      ..initialize().then((_) {
        setState(() {});
        _backgroundController.setLooping(true);
        _backgroundController.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          "assets/images/logo.png",
          width: 60,
          height: 60,
        ),
      ),
      body: Stack(
        children: [
          // Video background
          _backgroundController.value.isInitialized
              ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _backgroundController.value.size.width,
                height: _backgroundController.value.size.height,
                child: VideoPlayer(_backgroundController),
              ),
            ),
          )
              : Container(
            color: primaryDark,
          ),

          // Glass effect overlay dengan gradient biru
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    primaryBlue.withOpacity(0.2),
                    tealAccent.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Content overlay
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Glass video card dengan efek premium
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _controller.value.isInitialized
                                  ? SizedBox(
                                width: double.infinity,
                                height: 200,
                                child: VideoPlayer(_controller),
                              )
                                  : Container(
                                width: double.infinity,
                                height: 200,
                                color: lightBlue.withOpacity(0.2),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                  ),
                                ),
                              ),
                              
                              // Overlay gradient modern biru
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        tealAccent.withOpacity(0.15),
                                        primaryBlue.withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Text dengan efek gradient biru dan shadow premium
                              Text(
                                "Yoshimitsu",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        softWhite,
                                        cyanLight,
                                        royalBlue,
                                      ],
                                    ).createShader(const Rect.fromLTWH(0, 0, 300, 100)),
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(2, 2),
                                      blurRadius: 12,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    Shadow(
                                      offset: const Offset(-1, -1),
                                      blurRadius: 6,
                                      color: cyanLight.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 90),

                        const Text(
                          "Please Log in or Register to continue",
                          style: TextStyle(
                            color: Color(0xFFB0C4DE), // Light steel blue
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Elevated Button dengan gradient biru
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  primaryBlue,
                                  accentBlue,
                                  tealAccent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: tealAccent.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, "/login");
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Outlined Button dengan border gradient biru
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                width: 1.5,
                                color: Colors.transparent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ).copyWith(
                              side: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return BorderSide(
                                    width: 1.5,
                                    color: cyanLight,
                                  );
                                }
                                return BorderSide(
                                  width: 1.5,
                                  color: primaryBlue,
                                );
                              }),
                            ),
                            onPressed: () => _openUrl("https://store.nullxteam.fun"),
                            child: Text(
                              "Register",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: lightBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        "Contact Us",
                        style: TextStyle(
                            color: lightBlue.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryBlue.withOpacity(0.2),
                                  tealAccent.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.telegram,
                                color: cyanLight,
                                size: 28,
                              ),
                              onPressed: () => _openUrl("https://t.me/nullxteam"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "© 2025 Yoshimitsu",
                        style: TextStyle(
                          color: lightBlue.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}