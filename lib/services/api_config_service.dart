import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola Base URL dinamis dari GitHub Gist
class ApiConfigService {
  // Singleton pattern
  static final ApiConfigService _instance = ApiConfigService._internal();
  factory ApiConfigService() => _instance;
  ApiConfigService._internal();

  // GitHub Gist URL
  static const String _gistConfigUrl =
      'https://gist.githubusercontent.com/lx0025/7986fc07454e3f439106def54bd3a3cc/raw/config.json';

  // Header wajib
  static const Map<String, String> _requestHeaders = {
    'User-Agent': 'NBL-App/1.0',
    'Accept': 'application/json',
    'Cache-Control': 'no-cache',
  };

  // SharedPreferences keys
  static const String _prefKeyBaseUrl = 'cached_base_url';
  static const String _prefKeyUrlRat = 'cached_url_rat';
  static const String _prefKeyLastUpdate = 'last_update_timestamp';

  // Memory cache
  String? _cachedBaseUrl;
  String? _cachedUrlRat;

  bool _isLoading = false;

  /// Ambil Base URL
  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null && _cachedBaseUrl!.isNotEmpty) {
      return _cachedBaseUrl!;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_prefKeyBaseUrl);

    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      _cachedBaseUrl = cachedUrl;

      _fetchAndUpdateInBackground();
      return cachedUrl;
    }

    return await fetchBaseUrl();
  }

  /// Ambil URL RAT
  Future<String?> getUrlRat() async {
    if (_cachedUrlRat != null) return _cachedUrlRat;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefKeyUrlRat);

    if (cached != null) {
      _cachedUrlRat = cached;
      return cached;
    }

    // fallback fetch
    await getBaseUrl();
    return _cachedUrlRat;
  }

  /// Fetch dari Gist
  Future<String> fetchBaseUrl() async {
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedBaseUrl ?? await fetchBaseUrl();
    }

    _isLoading = true;

    try {
      print('🌐 Fetching config from Gist...');

      final response = await http
          .get(Uri.parse(_gistConfigUrl), headers: _requestHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final activeUrl = jsonData['url_aktif'] as String?;
        final urlRat = jsonData['url_rat'] as String?;

        if (activeUrl != null && activeUrl.isNotEmpty) {
          print('✅ Base URL: $activeUrl');
          print('✅ URL RAT: $urlRat');

          await _saveToCache(activeUrl, urlRat);

          _cachedBaseUrl = activeUrl;
          _cachedUrlRat = urlRat;

          _isLoading = false;
          return activeUrl;
        } else {
          throw Exception('Field "url_aktif" kosong / tidak ada');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      _isLoading = false;

      final cachedUrl = await _getCachedUrl();
      if (cachedUrl != null) {
        print('📦 Pakai cache: $cachedUrl');
        _cachedBaseUrl = cachedUrl;

        final prefs = await SharedPreferences.getInstance();
        _cachedUrlRat = prefs.getString(_prefKeyUrlRat);

        return cachedUrl;
      }

      throw Exception('Gagal ambil config & tidak ada cache');
    }
  }

  /// Background update
  Future<void> _fetchAndUpdateInBackground() async {
    try {
      final response = await http
          .get(Uri.parse(_gistConfigUrl), headers: _requestHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final activeUrl = jsonData['url_aktif'] as String?;
        final urlRat = jsonData['url_rat'] as String?;

        if (activeUrl != null && activeUrl.isNotEmpty) {
          await _saveToCache(activeUrl, urlRat);

          _cachedBaseUrl = activeUrl;
          _cachedUrlRat = urlRat;

          print('🔄 Updated (background)');
        }
      }
    } catch (_) {}
  }

  /// Save cache
  Future<void> _saveToCache(String url, String? urlRat) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_prefKeyBaseUrl, url);

    if (urlRat != null) {
      await prefs.setString(_prefKeyUrlRat, urlRat);
    }

    await prefs.setInt(
        _prefKeyLastUpdate, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _getCachedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyBaseUrl);
  }

  /// Force refresh
  Future<String> forceRefresh() async {
    _cachedBaseUrl = null;
    _cachedUrlRat = null;
    return await fetchBaseUrl();
  }

  /// Clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_prefKeyBaseUrl);
    await prefs.remove(_prefKeyUrlRat);
    await prefs.remove(_prefKeyLastUpdate);

    _cachedBaseUrl = null;
    _cachedUrlRat = null;
  }

  /// Last update
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_prefKeyLastUpdate);

    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Check update (1 jam)
  Future<bool> shouldUpdate() async {
    final lastUpdate = await getLastUpdateTime();

    if (lastUpdate == null) return true;

    final diff = DateTime.now().difference(lastUpdate);
    return diff.inHours >= 1;
  }
}

/// Helper class
class ApiConfig {
  static final ApiConfigService _service = ApiConfigService();

  static Future<String> get baseUrl async => await _service.getBaseUrl();

  static Future<String?> get urlRat async => await _service.getUrlRat();

  static Future<String> refresh() async => await _service.forceRefresh();

  static Future<void> clearCache() async => await _service.clearCache();
}