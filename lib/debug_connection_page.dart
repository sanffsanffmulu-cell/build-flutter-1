import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_config_service.dart';

class DebugConnectionPage extends StatefulWidget {
  const DebugConnectionPage({super.key});

  @override
  State<DebugConnectionPage> createState() => _DebugConnectionPageState();
}

class _DebugConnectionPageState extends State<DebugConnectionPage> {
  final List<String> _logs = [];
  bool _isTesting = false;
  int _selectedTab = 0;

  // Dark Blue Theme Colors
  static const Color darkBluePrimary = Color(0xFF0A1929);
  static const Color darkBlueSecondary = Color(0xFF0D2B3E);
  static const Color darkBlueCard = Color(0xFF0F2B3C);
  static const Color darkBlueAccent = Color(0xFF1E3A5F);
  static const Color darkBlueLight = Color(0xFF2C4C6E);
  static const Color darkBlueBorder = Color(0xFF1E3A5F);
  static const Color steelBlue = Color(0xFF4682B4);
  static const Color mutedBlue = Color(0xFF2C3E50);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _logs.clear();
      _isTesting = true;
    });

    _addLog('🚀 Starting diagnostics...');
    _addLog('');

    // Test 1: Fetch Gist Config
    _addLog('📡 TEST 1: Fetching Gist Config');
    _addLog('─────────────────────────────────');
    
    try {
      final gistUrl = 'https://gist.githubusercontent.com/lx0025/7986fc07454e3f439106def54bd3a3cc/raw/config.json';
      _addLog('URL: $gistUrl');
      
      final gistResponse = await http.get(Uri.parse(gistUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout after 10s');
        },
      );
      
      _addLog('Status: ${gistResponse.statusCode}');
      _addLog('Response: ${gistResponse.body}');
      
      if (gistResponse.statusCode == 200) {
        final data = jsonDecode(gistResponse.body);
        final urlAktif = data['url_aktif'];
        _addLog('✅ Gist OK! url_aktif = $urlAktif');
      } else {
        _addLog('❌ Gist failed with status ${gistResponse.statusCode}');
      }
    } catch (e) {
      _addLog('❌ Gist Error: $e');
    }
    
    _addLog('');
    
    // Test 2: ApiConfig.baseUrl
    _addLog('🔧 TEST 2: ApiConfig.baseUrl');
    _addLog('─────────────────────────────────');
    
    try {
      final baseUrl = await ApiConfig.baseUrl;
      _addLog('✅ ApiConfig.baseUrl = $baseUrl');
    } catch (e) {
      _addLog('❌ ApiConfig Error: $e');
    }
    
    _addLog('');
    
    // Test 3: Direct Server Ping
    _addLog('🌐 TEST 3: Direct Server Test');
    _addLog('─────────────────────────────────');
    
    try {
      final testUrl = 'http://ddosyatimkontol.zarxsft.my.id:3575';
      _addLog('Testing: $testUrl');
      
      final serverResponse = await http.get(Uri.parse(testUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Server timeout after 10s');
        },
      );
      
      _addLog('Status: ${serverResponse.statusCode}');
      _addLog('Response: ${serverResponse.body.substring(0, serverResponse.body.length > 100 ? 100 : serverResponse.body.length)}...');
      _addLog('✅ Server reachable!');
    } catch (e) {
      _addLog('❌ Server Error: $e');
    }
    
    _addLog('');
    
    // Test 4: API Validate Endpoint
    _addLog('🔐 TEST 4: API Validate Endpoint');
    _addLog('─────────────────────────────────');
    
    try {
      final baseUrl = await ApiConfig.baseUrl;
      final validateUrl = '$baseUrl/api/auth/validate';
      _addLog('URL: $validateUrl');
      
      final validateResponse = await http.post(
        Uri.parse(validateUrl),
        body: {
          'username': 'test',
          'password': 'test',
          'androidId': 'test123',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Validate timeout after 10s');
        },
      );
      
      _addLog('Status: ${validateResponse.statusCode}');
      _addLog('Response: ${validateResponse.body}');
      
      if (validateResponse.statusCode == 200) {
        _addLog('✅ API Endpoint reachable!');
      } else {
        _addLog('⚠️ Endpoint responded but status: ${validateResponse.statusCode}');
      }
    } catch (e) {
      _addLog('❌ API Error: $e');
    }
    
    _addLog('');
    _addLog('═══════════════════════════════════');
    _addLog('🏁 Diagnostics Complete');
    _addLog('═══════════════════════════════════');

    setState(() {
      _isTesting = false;
    });
  }

  Future<void> _testWithRealCredentials() async {
    setState(() {
      _logs.clear();
      _isTesting = true;
    });

    _addLog('🔑 Testing with Real Login');
    _addLog('─────────────────────────────────');
    
    String? username;
    String? password;
    
    await showDialog(
      context: context,
      builder: (context) {
        final userCtrl = TextEditingController();
        final passCtrl = TextEditingController();
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkBlueCard, darkBlueSecondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: darkBlueAccent.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: steelBlue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter Credentials',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: darkBlueLight),
                    prefixIcon: const Icon(Icons.person, color: steelBlue),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darkBlueLight.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: steelBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: darkBlueLight),
                    prefixIcon: const Icon(Icons.lock, color: steelBlue),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darkBlueLight.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: steelBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          username = userCtrl.text;
                          password = passCtrl.text;
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: steelBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Test Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (username != null && password != null) {
      try {
        final baseUrl = await ApiConfig.baseUrl;
        _addLog('Base URL: $baseUrl');
        _addLog('Username: $username');
        _addLog('Sending request...');
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/auth/validate'),
          body: {
            'username': username!,
            'password': password!,
            'androidId': 'debug_test',
          },
        ).timeout(const Duration(seconds: 15));
        
        _addLog('Status: ${response.statusCode}');
        _addLog('Response: ${response.body}');
        
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _addLog('✅ LOGIN SUCCESS!');
          _showSnackbar('Login Successful!', successGreen);
        } else if (data['expired'] == true) {
          _addLog('⚠️ Account expired');
          _showSnackbar('Account Expired', warningOrange);
        } else {
          _addLog('❌ Invalid credentials');
          _showSnackbar('Invalid Credentials', errorRed);
        }
      } catch (e) {
        _addLog('❌ Error: $e');
        _showSnackbar('Error: $e', errorRed);
      }
    }

    setState(() {
      _isTesting = false;
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearCache() async {
    _addLog('🗑️ Clearing cache...');
    try {
      await ApiConfig.clearCache();
      _addLog('✅ Cache cleared');
      _showSnackbar('Cache Cleared', successGreen);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackbar('Error clearing cache', errorRed);
    }
  }

  Future<void> _forceRefresh() async {
    _addLog('🔄 Force refreshing from Gist...');
    try {
      final newUrl = await ApiConfig.refresh();
      _addLog('✅ New URL: $newUrl');
      _showSnackbar('Config Refreshed!', successGreen);
    } catch (e) {
      _addLog('❌ Error: $e');
      _showSnackbar('Error refreshing config', errorRed);
    }
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBlueAccent, darkBlueSecondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkBlueAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.network_check,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isTesting ? 'Testing...' : 'Ready to test',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isTesting ? warningOrange : successGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              _isTesting ? Icons.hourglass_empty : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBluePrimary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: steelBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bug_report, color: steelBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Connection Diagnostics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: darkBlueSecondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: steelBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_sweep, color: steelBlue),
            ),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              _showSnackbar('Logs cleared', darkBlueLight);
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          
          // Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: darkBlueSecondary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Diagnostics', Icons.science),
                _buildTabButton(1, 'Actions', Icons.touch_app),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0 ? _buildLogsView() : _buildActionsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? steelBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : darkBlueLight,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : darkBlueLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Run Diagnostics',
            description: 'Test all connections and endpoints',
            color: steelBlue,
            onPressed: _isTesting ? null : _runDiagnostics,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.login,
            label: 'Test Login',
            description: 'Test with real credentials',
            color: darkBlueLight,
            onPressed: _isTesting ? null : _testWithRealCredentials,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Clear Cache',
            description: 'Clear stored configuration cache',
            color: warningOrange,
            onPressed: _isTesting ? null : _clearCache,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Force Refresh',
            description: 'Refresh config from Gist',
            color: steelBlue,
            onPressed: _isTesting ? null : _forceRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: darkBlueCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogsView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBlueCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkBlueBorder.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: darkBlueSecondary,
                border: Border(
                  bottom: BorderSide(color: darkBlueBorder.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: steelBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.terminal,
                      color: steelBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Console Output',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_logs.isNotEmpty)
                    Text(
                      '${_logs.length} lines',
                      style: TextStyle(
                        color: darkBlueLight,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_off,
                            color: darkBlueLight.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No logs yet',
                            style: TextStyle(
                              color: darkBlueLight.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Press "Run Diagnostics" to start',
                            style: TextStyle(
                              color: darkBlueLight.withOpacity(0.3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color textColor = successGreen;
                        
                        if (log.contains('❌')) {
                          textColor = errorRed;
                        } else if (log.contains('⚠️')) {
                          textColor = warningOrange;
                        } else if (log.contains('✅')) {
                          textColor = successGreen;
                        } else if (log.contains('─') || log.contains('═')) {
                          textColor = steelBlue;
                        } else if (log.contains('🚀') || log.contains('🏁')) {
                          textColor = steelBlue;
                        } else {
                          textColor = Colors.white;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.substring(0, 10),
                                style: TextStyle(
                                  color: darkBlueLight.withOpacity(0.6),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  log.substring(11),
                                  style: TextStyle(
                                    color: textColor,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}