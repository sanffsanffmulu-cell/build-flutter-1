import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Ayat {
  final int nomor;
  final String arab;
  final String arti;

  Ayat({
    required this.nomor,
    required this.arab,
    required this.arti,
  });
}

class Surat {
  final int nomor;
  final String nama;
  final String latin;
  final List<Ayat> ayat;
  final int juz;

  Surat({
    required this.nomor,
    required this.nama,
    required this.latin,
    required this.ayat,
    required this.juz,
  });
}

class Juz {
  final int nomor;
  final List<Surat> suratList;
  final int suratMulai;
  final int suratAkhir;
  final int ayatMulai;
  final int ayatAkhir;

  Juz({
    required this.nomor,
    required this.suratList,
    required this.suratMulai,
    required this.suratAkhir,
    required this.ayatMulai,
    required this.ayatAkhir,
  });
}

class AlQuranPage extends StatefulWidget {
  const AlQuranPage({super.key});

  @override
  State<AlQuranPage> createState() => _AlQuranPageState();
}

class _AlQuranPageState extends State<AlQuranPage> {
  bool loading = true;
  List<Surat> allSuratList = [];
  List<Juz> juzList = [];
  List<Juz> filteredJuzList = [];
  TextEditingController searchController = TextEditingController();
  bool showJuzList = true;
  Juz? selectedJuz;

  // Dark theme blue color palette
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color secondaryBlue = const Color(0xFF60A5FA);
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color deepBlue = const Color(0xFF0F172A);
  final Color cardDark = const Color(0xFF1E293B);
  final Color softBg = const Color(0xFF0F172A);
  final Color textPrimary = const Color(0xFFF1F5F9);
  final Color textSecondary = const Color(0xFF94A3B8);
  final Color dividerColor = const Color(0xFF334155);

  // Data pembagian juz berdasarkan surat dan ayat
  // Ini adalah data ringkas batas-batas juz
  final List<Map<String, int>> juzBatas = [
    {'juz': 1, 'surat': 1, 'ayat': 1, 'suratAkhir': 2, 'ayatAkhir': 141},
    {'juz': 2, 'surat': 2, 'ayat': 142, 'suratAkhir': 2, 'ayatAkhir': 252},
    {'juz': 3, 'surat': 2, 'ayat': 253, 'suratAkhir': 3, 'ayatAkhir': 92},
    {'juz': 4, 'surat': 3, 'ayat': 93, 'suratAkhir': 4, 'ayatAkhir': 23},
    {'juz': 5, 'surat': 4, 'ayat': 24, 'suratAkhir': 4, 'ayatAkhir': 147},
    {'juz': 6, 'surat': 4, 'ayat': 148, 'suratAkhir': 5, 'ayatAkhir': 81},
    {'juz': 7, 'surat': 5, 'ayat': 82, 'suratAkhir': 6, 'ayatAkhir': 110},
    {'juz': 8, 'surat': 6, 'ayat': 111, 'suratAkhir': 7, 'ayatAkhir': 87},
    {'juz': 9, 'surat': 7, 'ayat': 88, 'suratAkhir': 8, 'ayatAkhir': 40},
    {'juz': 10, 'surat': 8, 'ayat': 41, 'suratAkhir': 9, 'ayatAkhir': 92},
    {'juz': 11, 'surat': 9, 'ayat': 93, 'suratAkhir': 11, 'ayatAkhir': 5},
    {'juz': 12, 'surat': 11, 'ayat': 6, 'suratAkhir': 12, 'ayatAkhir': 52},
    {'juz': 13, 'surat': 12, 'ayat': 53, 'suratAkhir': 14, 'ayatAkhir': 52},
    {'juz': 14, 'surat': 15, 'ayat': 1, 'suratAkhir': 16, 'ayatAkhir': 128},
    {'juz': 15, 'surat': 17, 'ayat': 1, 'suratAkhir': 18, 'ayatAkhir': 74},
    {'juz': 16, 'surat': 18, 'ayat': 75, 'suratAkhir': 20, 'ayatAkhir': 135},
    {'juz': 17, 'surat': 21, 'ayat': 1, 'suratAkhir': 22, 'ayatAkhir': 78},
    {'juz': 18, 'surat': 23, 'ayat': 1, 'suratAkhir': 25, 'ayatAkhir': 20},
    {'juz': 19, 'surat': 25, 'ayat': 21, 'suratAkhir': 27, 'ayatAkhir': 55},
    {'juz': 20, 'surat': 27, 'ayat': 56, 'suratAkhir': 29, 'ayatAkhir': 45},
    {'juz': 21, 'surat': 29, 'ayat': 46, 'suratAkhir': 33, 'ayatAkhir': 30},
    {'juz': 22, 'surat': 33, 'ayat': 31, 'suratAkhir': 36, 'ayatAkhir': 27},
    {'juz': 23, 'surat': 36, 'ayat': 28, 'suratAkhir': 39, 'ayatAkhir': 31},
    {'juz': 24, 'surat': 39, 'ayat': 32, 'suratAkhir': 41, 'ayatAkhir': 46},
    {'juz': 25, 'surat': 41, 'ayat': 47, 'suratAkhir': 45, 'ayatAkhir': 37},
    {'juz': 26, 'surat': 46, 'ayat': 1, 'suratAkhir': 51, 'ayatAkhir': 30},
    {'juz': 27, 'surat': 51, 'ayat': 31, 'suratAkhir': 57, 'ayatAkhir': 29},
    {'juz': 28, 'surat': 58, 'ayat': 1, 'suratAkhir': 66, 'ayatAkhir': 12},
    {'juz': 29, 'surat': 67, 'ayat': 1, 'suratAkhir': 77, 'ayatAkhir': 50},
    {'juz': 30, 'surat': 78, 'ayat': 1, 'suratAkhir': 114, 'ayatAkhir': 6},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuran();
    searchController.addListener(_filterJuz);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterJuz);
    searchController.dispose();
    super.dispose();
  }

  void _filterJuz() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredJuzList = List.from(juzList);
      } else {
        filteredJuzList = juzList.where((juz) {
          return juz.nomor.toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadQuran() async {
    try {
      final arabRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'),
      );
      final indoRes = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/quran/id.indonesian'),
      );

      if (arabRes.statusCode != 200 || indoRes.statusCode != 200) {
        throw Exception('Failed to load data');
      }

      final arabData = jsonDecode(arabRes.body) as Map<String, dynamic>;
      final indoData = jsonDecode(indoRes.body) as Map<String, dynamic>;

      final arabSurah = (arabData['data'] as Map<String, dynamic>)['surahs'] as List;
      final indoSurah = (indoData['data'] as Map<String, dynamic>)['surahs'] as List;

      List<Surat> result = [];

      for (int i = 0; i < arabSurah.length; i++) {
        final arabSurahData = arabSurah[i] as Map<String, dynamic>;
        final indoSurahData = indoSurah[i] as Map<String, dynamic>;
        
        final arabAyat = arabSurahData['ayahs'] as List;
        final indoAyat = indoSurahData['ayahs'] as List;

        List<Ayat> ayatList = [];

        for (int j = 0; j < arabAyat.length; j++) {
          final arabAyatData = arabAyat[j] as Map<String, dynamic>;
          final indoAyatData = indoAyat[j] as Map<String, dynamic>;
          
          // Menentukan juz berdasarkan nomor surat dan ayat
          int juzNumber = _getJuzNumber(i + 1, j + 1);
          
          ayatList.add(
            Ayat(
              nomor: arabAyatData['numberInSurah'] as int,
              arab: arabAyatData['text'] as String? ?? '',
              arti: indoAyatData['text'] as String? ?? '',
            ),
          );
        }

        result.add(
          Surat(
            nomor: arabSurahData['number'] as int,
            nama: arabSurahData['name'] as String? ?? '',
            latin: arabSurahData['englishName'] as String? ?? '',
            ayat: ayatList,
            juz: _getJuzNumber(arabSurahData['number'] as int, 1),
          ),
        );
      }

      setState(() {
        allSuratList = result;
        _buildJuzList();
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading Quran: $e');
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getJuzNumber(int suratNumber, int ayatNumber) {
    for (var batas in juzBatas) {
      if (suratNumber > batas['surat']! ||
          (suratNumber == batas['surat']! && ayatNumber >= batas['ayat']!)) {
        if (suratNumber < batas['suratAkhir']! ||
            (suratNumber == batas['suratAkhir']! && ayatNumber <= batas['ayatAkhir']!)) {
          return batas['juz']!;
        }
      }
    }
    return 30; // default juz 30
  }

  void _buildJuzList() {
    juzList = [];
    for (int i = 1; i <= 30; i++) {
      List<Surat> suratInJuz = [];
      for (var surat in allSuratList) {
        // Cek apakah surat termasuk dalam juz ini
        bool isInJuz = false;
        for (var batas in juzBatas) {
          if (batas['juz'] == i) {
            if (surat.nomor >= batas['surat']! && surat.nomor <= batas['suratAkhir']!) {
              isInJuz = true;
              break;
            }
          }
        }
        if (isInJuz) {
          suratInJuz.add(surat);
        }
      }
      
      var batas = juzBatas.firstWhere((b) => b['juz'] == i);
      juzList.add(
        Juz(
          nomor: i,
          suratList: suratInJuz,
          suratMulai: batas['surat']!,
          suratAkhir: batas['suratAkhir']!,
          ayatMulai: batas['ayat']!,
          ayatAkhir: batas['ayatAkhir']!,
        ),
      );
    }
    filteredJuzList = List.from(juzList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: deepBlue,
        elevation: 0,
        centerTitle: true,
        leading: showJuzList || selectedJuz == null
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: primaryBlue),
                onPressed: () {
                  setState(() {
                    showJuzList = true;
                    selectedJuz = null;
                  });
                },
              ),
        title: Text(
          showJuzList ? 'AL-QUR\'AN' : 'JUZ ${selectedJuz?.nomor ?? ""}',
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 2,
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: dividerColor,
          ),
        ),
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat Al-Qur\'an...',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : showJuzList
              ? _buildJuzListView()
              : _buildSuratInJuzView(),
    );
  }

  Widget _buildJuzListView() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: softBg,
          child: Container(
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(20), // Lebih tumpul
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Cari Juz (1-30)',
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: primaryBlue,
                  size: 20,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Lebih tumpul
                  borderSide: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Lebih tumpul
                  borderSide: BorderSide(
                    color: dividerColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Lebih tumpul
                  borderSide: BorderSide(
                    color: primaryBlue,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        // Search Result Info
        if (searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Ditemukan ${filteredJuzList.length} juz',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    searchController.clear();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Bersihkan',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // List of Juz
        Expanded(
          child: filteredJuzList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Juz tidak ditemukan',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          searchController.clear();
                        },
                        child: Text(
                          'Coba kata kunci lain',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filteredJuzList.length,
                  itemBuilder: (context, index) {
                    return _juzCard(filteredJuzList[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _juzCard(Juz juz) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedJuz = juz;
          showJuzList = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardDark,
              deepBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(24), // Lebih tumpul
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryBlue.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${juz.nomor}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Juz ${juz.nomor}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Surat ${juz.suratMulai} - ${juz.suratAkhir}',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuratInJuzView() {
    if (selectedJuz == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Juz Info Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.2),
                deepBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(28), // Lebih tumpul
            border: Border.all(
              color: primaryBlue.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'JUZ ${selectedJuz!.nomor}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(
                      'Surat ${selectedJuz!.suratMulai} - ${selectedJuz!.suratAkhir}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Lebih tumpul
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      'Ayat ${selectedJuz!.ayatMulai} - ${selectedJuz!.ayatAkhir}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Lebih tumpul
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // List of Surahs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: selectedJuz!.suratList.length,
            itemBuilder: (context, index) {
              return _suratCard(selectedJuz!.suratList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _suratCard(Surat surat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20), // Lebih tumpul
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        iconColor: primaryBlue,
        collapsedIconColor: primaryBlue,
        collapsedTextColor: textPrimary,
        textColor: primaryBlue,
        backgroundColor: cardDark,
        collapsedBackgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Lebih tumpul
        ),
        title: Text(
          '${surat.nomor}. ${surat.latin}',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: textPrimary,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          surat.nama,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: surat.ayat.map(_ayatTile).toList(),
      ),
    );
  }

  Widget _ayatTile(Ayat ayat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deepBlue,
        borderRadius: BorderRadius.circular(20), // Lebih tumpul
        border: Border.all(
          color: dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30), // Lebih tumpul
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Ayat ${ayat.nomor}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: secondaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ayat.arab,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 22,
              height: 1.8,
              color: textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: dividerColor,
            height: 1,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ayat.arti,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}