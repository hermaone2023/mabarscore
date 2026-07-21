import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/constants/blink_effect.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  // Masukkan fungsi ini di dalam class State HomeView kawan
  Future<List<dynamic>> fetchTopPlayers() async {
    try {
      final response = await http.get(
        Uri.parse('https://donorta.tech/apimabarscore/get_top_players.php'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        }
      }
      return [];
    } catch (e) {
      print("Error fetch top players: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchActiveBatch() async {
    try {
      final response = await http.get(
        Uri.parse('https://donorta.tech/apimabarscore/get_active_batch.php'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; // Mengembalikan objek data {}
        }
      }
      return null;
    } catch (e) {
      print("Error fetch active batch: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Menggunakan Column Utama untuk memisahkan area STICKY dan SCROLLABLE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 📌 1. AREA STICKY (MELAYANG/DIAM DI ATAS)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER BRANDING MABARSCORE ---
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logoms.png',
                              height: 50,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.blur_on,
                                    color: Color(0xFFF3A93B),
                                    size: 35,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'mabarscore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // --- BADGE TURNAMEN ONLINE ---
                        Row(
                          children: [
                            const BlinkingIndicator(),
                            const SizedBox(width: 8),
                            Text(
                              'TURNAMEN ONLINE',
                              style: TextStyle(
                                color: Color(0xFFE4C367),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // --- JUDUL SEASON UTAMA ---
                        FutureBuilder<Map<String, dynamic>?>(
                          future: fetchActiveBatch(),
                          builder: (context, snapshot) {
                            // 1. Teks Default / Cadangan saat loading atau jika data gagal dimuat kawan
                            String batchText = 'BATCH -';

                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data != null) {
                              final batchData = snapshot.data!;
                              // Mengambil batch_id atau nama_batch dari API kawan
                              final batchId = batchData['batch_id'] ?? '-';
                              batchText = '$batchId'.toUpperCase();

                              // ALTERNATIF: Kalau kawan mau pakai "nama_batch" (misal hasilnya: BATCH-1), ganti kodenya jadi:
                              // batchText = (batchData['nama_batch'] ?? '-').toString().toUpperCase();
                            }

                            return Text(
                              'MOBILE LEGEND BY ONE\nSEASON $batchText', // 🔥 Hasilnya otomatis: MOBILE LEGEND BY ONE SEASON 1 BATCH 1
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 📜 2. AREA SCROLLABLE (KONTEN BISA DI-SCROLL)
                  // ==========================================
                  Expanded(
                    child: SingleChildScrollView(
                      physics:
                          const BouncingScrollPhysics(), // Efek mantul iOS-style yang halus kawan
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        5,
                        20,
                        100,
                      ), // Padding bawah 100 agar konten tidak tertutup Floating Navbar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- KARTU TOTAL HADIAH ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardHeaderGradient,
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: AssetImage('assets/images/bghome.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/winner.png',
                                  height: 45,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL HADIAH FINALIS',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Rp. 7. 000. 000',
                                        style: TextStyle(
                                          color: Color(0xFFEDBA5E),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Dengan skill dan strategi terbaik, raih kemenanganmu dan menjadi finalis di turnamen ini!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          // =========================================================================
                          // 🏆 SEKTOR TOP PLAYER SEASON (BISA DI-SCROLL KANAN-KIRI) KAWAN 🏆
                          // =========================================================================
                          const Text(
                            'Top player season',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 🔥 Menggunakan FutureBuilder untuk menjembatani API MabarScore kawan
                          FutureBuilder<List<dynamic>>(
                            future: fetchTopPlayers(),
                            builder: (context, snapshot) {
                              // 1. Kondisi saat data masih loading/loading dari server donorta.tech
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 90,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFEDBA5E),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 2. Kondisi jika terjadi error atau data kosong
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const SizedBox(
                                  height: 90,
                                  child: Center(
                                    child: Text(
                                      'Belum ada data juara season ini kawan',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 3. Kondisi Sukses: Data berhasil didapatkan dari backend kawan!
                              final topPlayers = snapshot.data!;

                              return SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: topPlayers
                                      .length, // Menyesuaikan jumlah data dari API kawan
                                  itemBuilder: (context, index) {
                                    // Parsing data item dari JSON API
                                    final player = topPlayers[index];
                                    final int peringkat =
                                        player['peringkat'] ?? 2;
                                    final isJuara1 =
                                        peringkat ==
                                        1; // Otomatis emas jika peringkat 1 dari database

                                    final String nickname =
                                        player['nickname'] ?? 'No Name';
                                    final String mlbbId =
                                        player['mlbb_id'] ?? '-';
                                    final String season =
                                        player['season'] ?? 'Season ?';
                                    final String rawTahun =
                                        player['tahun'] ?? '-';
                                    final String tahun = rawTahun.contains('-')
                                        ? rawTahun.split('-')[0]
                                        : rawTahun;

                                    return Container(
                                      width: 290,
                                      margin: const EdgeInsets.only(right: 15),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        // color: const Color(0xFF0B6357), // Silakan aktifkan jika butuh warna dasar box
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isJuara1
                                              ? const Color(
                                                  0xFFEDBA5E,
                                                ) // Border Emas untuk Peringkat 1
                                              : const Color(
                                                  0xFF1B8A7A,
                                                ), // Border Hijau Toska untuk Peringkat lainnya
                                          width: isJuara1 ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // 🔴 Avatar Player (Bisa dikembangkan pakai network image jika ada kolomnya nanti kawan)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              color: isJuara1
                                                  ? Colors.purple.shade900
                                                  : Colors.blue.shade900,
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // 📝 Detail Juara Real-time dari API MabarScore kawan
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  nickname, // Menampilkan Nickname Dinamis
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'ID $mlbbId', // Menampilkan MLBB ID Dinamis
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.6),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.military_tech,
                                                      color: isJuara1
                                                          ? const Color(
                                                              0xFFEDBA5E,
                                                            )
                                                          : Colors
                                                                .grey
                                                                .shade300,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        'Peringkat $peringkat $season $tahun', // Informasi Babak & Season Lengkap
                                                        style: TextStyle(
                                                          color: isJuara1
                                                              ? Colors
                                                                    .yellow
                                                                    .shade400
                                                              : Colors
                                                                    .grey
                                                                    .shade300,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 🏆 Ikon Mahkota/Medali Penanda Juara
                                          Icon(
                                            isJuara1
                                                ? Icons.emoji_events
                                                : Icons.military_tech_outlined,
                                            color: isJuara1
                                                ? const Color(0xFFEDBA5E)
                                                : const Color(0xFF1A5A50),
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 25),
                          // =========================================================================
                          const Text(
                            'News & Update',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // --- SEKTOR MABARSCORE NEWS ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5E5C),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.blur_on,
                                      color: Color(0xFFEDBA5E),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'mabarscore news',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Jun, 2026',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    height: 160,
                                    color: Colors.black26,
                                    child: const Center(
                                      child: Text(
                                        'ALL HEROES MOBILE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ==========================================
              // 🛸 3. FLOATING BOTTOM NAVIGATION BAR (TETAP MELAYANG DI ATAS SEGALA LAPISAN)
              // ==========================================
              Positioned(
                left: 30,
                right: 30,
                bottom: 25,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: const Color(0xFF556066).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.emoji_events, 'Home'),
                      _buildNavItem(1, Icons.hub, 'Fivehero'),
                      _buildNavItem(2, Icons.person, 'Profile'),
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF232D32) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFFEDBA5E)
              : Colors.white.withValues(alpha: 0.7),
          size: 28,
        ),
      ),
    );
  }
}
