import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _qrImage;
  String? _errorMessage;

  // 🎨 PALETTE BIRU
  final Color primaryDark = const Color(0xFF0A1929);
  final Color primaryBlue = const Color(0xFF2B4F8C);
  final Color accentBlue = const Color(0xFF1E3A6F);
  final Color lightBlue = const Color(0xFF4A7DB5);
  final Color softWhite = const Color(0xFFF0F4FA);
  final Color cardBlue = const Color(0xFF13263E);
  final Color tealAccent = const Color(0xFF1B9C9C);
  final Color cyanLight = const Color(0xFF4ECDC4);

  Future<void> _generateQR() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Text tidak boleh kosong.";
        _qrImage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrImage = null;
    });

    final encodedText = Uri.encodeComponent(text);
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/text2qr?text=$encodedText");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _qrImage = response.bodyBytes;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal generate QR Code.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareQR() async {
    if (_qrImage == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_qrImage!);

      await Share.shareXFiles([XFile(file.path)],
        text: 'QR Code dari: ${_textController.text}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e', style: TextStyle(color: softWhite)),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: Text(
          'QR GENERATOR',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: softWhite,
          ),
        ),
        backgroundColor: primaryDark,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: softWhite),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cyanLight.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: cyanLight.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _textController,
                      style: TextStyle(color: softWhite, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan Text/URL',
                        labelStyle: TextStyle(color: cyanLight),
                        hintText: 'Contoh: https://google.com',
                        hintStyle: TextStyle(color: softWhite.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cyanLight.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: cyanLight, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: primaryDark.withOpacity(0.3),
                        suffixIcon: _isLoading
                            ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: cyanLight,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (_) => _generateQR(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryBlue, cyanLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyanLight.withOpacity(0.5),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _generateQR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: softWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isLoading ? Icons.hourglass_top : Icons.qr_code, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isLoading ? 'GENERATING...' : 'GENERATE QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // QR Result
              if (_qrImage != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBlue,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cyanLight.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: cyanLight.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // QR Code Container
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: softWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cyanLight, width: 2),
                                ),
                                child: Image.memory(_qrImage!),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [tealAccent, cyanLight],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cyanLight.withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _shareQR,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: softWhite,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.share, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'SHARE QR CODE',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Orbitron',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Info Text
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cyanLight.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: cyanLight, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'QR Code berhasil digenerate!',
                                        style: TextStyle(
                                          color: cyanLight,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                  ),
                ),

              // Placeholder ketika belum generate QR
              if (_qrImage == null && !_isLoading && _errorMessage == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: primaryBlue.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Generate QR Code',
                          style: TextStyle(
                            color: softWhite.withOpacity(0.7),
                            fontSize: 18,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Masukkan text atau URL untuk membuat QR Code',
                          style: TextStyle(
                            color: softWhite.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}