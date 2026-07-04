import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'hadith_data.dart';
import 'hadith_detail_page.dart';

class HadithWidget extends StatefulWidget {
  const HadithWidget({super.key});

  @override
  State<HadithWidget> createState() => _HadithWidgetState();
}

class _HadithWidgetState extends State<HadithWidget> with TickerProviderStateMixin {
  Map<String, dynamic> _currentHadith = HadithData.hadiths[0];
  bool _isLoading = false;
  Timer? _refreshTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _loadHadith();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Refresh setiap 24 jam
    _refreshTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _loadHadith();
    });
  }

  Future<void> _loadHadith() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulasi loading sebentar
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    setState(() {
      _currentHadith = HadithData.getRandomHadith();
      _isLoading = false;
    });
    
    // Trigger animasi fade
    _fadeController.reset();
    _fadeController.forward();
  }

  String _getKitabName(String kitab) {
    return kitab;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF1E3A5F),  // Menghapus .withOpacity
              Color(0xFF0D2135),  // Menghapus .withOpacity
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2196F3),  // Menghapus .withOpacity
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HadithDetailPage(
                    hadith: _currentHadith,
                    onRefresh: _loadHadith,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan tombol refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "HADITH OF THE DAY",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Tombol refresh manual
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2196F3),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF2196F3),
                                      size: 18,
                                    ),
                              onPressed: _isLoading ? null : () async {
                                await _loadHadith();
                              },
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getKitabName(_currentHadith['kitab']),
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Arabic Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _currentHadith['arab'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.8,
                        fontFamily: 'Scheherazade',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Translation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Rasulullah ﷺ bersabda: ',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${_currentHadith['kitab']} #${_currentHadith['nomor']}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentHadith['terjemahan'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Auto-refresh setiap 24 jam",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Tap for full",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: const Color(0xFF2196F3),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}