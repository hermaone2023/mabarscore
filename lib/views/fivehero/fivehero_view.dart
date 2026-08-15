import 'dart:convert'; // Tambahkan ini kawan jika belum ada untuk jsonDecode
import 'package:flutter/material.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/fivehero/fivehero_detail_view.dart';
import 'package:mabarscore/views/fivehero/jadwal_batch_page.dart';
import 'package:mabarscore/views/profile/dokumentasi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FiveheroView extends StatefulWidget {
  const FiveheroView({Key? key}) : super(key: key);

  @override
  State<FiveheroView> createState() => _FiveheroViewState();
}

class _FiveheroViewState extends State<FiveheroView> {
  int userCoin = 0;
  List<dynamic> arenas = [];
  bool _isLoading = true;
  int currentBatchId = 1;
  int currentRound = 1; // 🔥 KAWAN: State mencatat babak aktif saat ini
  String currentUserGoogleId = "";

  // 🔥 KAWAN: Tambahan state penampung interceptor podium juara
  bool isTournamentOver = false;
  String winnerName = "";
  String winnerPhoto = "";
  String winnerGoogleId = "";

  bool _isFirstLoad = true;
  static const String _prefKeyJanganTampilkan =
      'jangan_tampilkan_aturan_turnamen';

  Future<void> _cekStatusDanTampilkanBottomSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final bool janganTampilkan =
        prefs.getBool(_prefKeyJanganTampilkan) ?? false;

    // Gunakan print biasa agar pasti tampil di Logcat/Terminal Android Studio
    print("Status Jangan Tampilkan Lagi: $janganTampilkan");

    // Jika belum pernah dicentang dan widget aktif, tampilkan bottom sheet otomatis
    if (!janganTampilkan && mounted) {
      _showAturanTurnamenBottomSheet();
    }
  }

  // KAWAN: Fungsi untuk memotong nama batch agar rapi di UI (misal BATCH-1 -> BATCH)
  String _cleanBatchName(String rawName) {
    return rawName.contains('-') ? rawName.split('-')[0] : rawName;
  }

  // KAWAN: Kita buat satu fungsi inisialisasi yang teratur jalurnya
  Future<void> _initData() async {
    try {
      // 1. Ambil session user dulu kawan
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString('user_session');

      if (sessionString != null) {
        final Map<String, dynamic> userData = jsonDecode(sessionString);
        if (mounted) {
          setState(() {
            currentUserGoogleId = userData['google_id'] ?? "";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            currentUserGoogleId = prefs.getString('google_id') ?? "";
          });
        }
      }
      print("Google ID terdeteksi di Arena kawan: $currentUserGoogleId");
    } catch (e) {
      print("Gagal memuat session google_id kawan: $e");
    }

    // 2. Setelah session aman, baru panggil fetch data MySQL kawan
    await _fetchArenas();
  }

  Future<void> _fetchArenas() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final int activeBatchId = await ApiService().getActiveBatchId();

      // 1. Ambil data arena master dulu seperti biasa kawan
      final freshData = await ApiService().getArenasData(
        batchId: activeBatchId,
        googleId: currentUserGoogleId,
      );

      int detectedRound = 1;
      bool overCheck = false;
      String wName = "";
      String wPhoto = "";
      String wGId = "";

      if (freshData.isNotEmpty) {
        if (freshData[0]['round'] != null) {
          detectedRound = int.tryParse(freshData[0]['round'].toString()) ?? 1;
        }

        // 2. Jika terdeteksi Round 3, panggil API sekali lagi khusus menarik data match round 3 kawan
        if (detectedRound == 4) {
          final matchDataRound3 = await ApiService().getArenasData(
            batchId: activeBatchId,
            googleId: currentUserGoogleId,
            round: 4, // 🔥 SUNTIK PARAMETER ROUND DISINI
          );

          // Cek di dalam baris match round 3, apakah sudah ada pemenangnya
          for (var match in matchDataRound3) {
            if (match['pemenang_id'] != null &&
                match['pemenang_id'].toString().isNotEmpty &&
                match['pemenang_id'] != 'NULL') {
              overCheck = true;
              wName = match['pemenang_nama'] ?? "Pro Player";
              wPhoto = match['pemenang_foto'] ?? "";
              wGId = match['pemenang_id'].toString();
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          currentBatchId = activeBatchId;
          currentRound = detectedRound;
          arenas = freshData;
          isTournamentOver = overCheck;
          winnerName = wName;
          winnerPhoto = wPhoto;
          winnerGoogleId = wGId;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Gagal memuat ulang data arena kawan: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initData();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      // 🔥 Cukup panggil pengecekan SharedPreferences di sini secara aman
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cekStatusDanTampilkanBottomSheet();
      });
    }
  }

  void _showAturanTurnamenBottomSheet() {
    bool janganTampilkanLagi = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(
        233,
        14,
        34,
        36,
      ), // Warna tema gelap selaras
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        // 🔥 Bungkus dengan StatefulBuilder agar checkbox reaktif dan setStateModal dikenali
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Garis Indikator Atas
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Judul
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/iconms.png', height: 30),
                      const SizedBox(
                        height: 8,
                      ), // Perbaikan dari SizedBox(width: 8) karena dalam Column
                      const Text(
                        "Selamat datang di Mabarscore",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Aturan & Tata Cara Singkat
                  const Text(
                    "Mabarscore adalah platform penyedian turnamen online yang saat ini fokus ke turnamen Mobile Legends Bang Bang, untuk mengetahui aturan dan tata cara mengikuti turnamen, silakan baca dokumentasi lengkapnya di halaman dokumentasi. Pastikan kamu membaca dan memahami aturan main dengan baik.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkbox "Jangan Tampilkan Lagi"
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: janganTampilkanLagi,
                          activeColor: Colors.greenAccent,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (bool? value) {
                            setStateModal(() {
                              janganTampilkanLagi = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Jangan tampilkan lagi",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Baca Selengkapnya Dokumentasi
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Tutup bottom sheet dulu
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DokumentasiView(), // Ganti dengan halaman dokumentasi lengkap Anda
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.book_outlined,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      label: const Text(
                        "Baca Selengkapnya",
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amberAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol Mengerti
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 🔥 Simpan ke SharedPreferences jika opsi "Jangan tampilkan lagi" dicentang
                        if (janganTampilkanLagi) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(_prefKeyJanganTampilkan, true);
                          print("BERHASIL MENYIMPAN: true");
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF145347),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Mengerti",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
          image: DecorationImage(
            image: AssetImage('assets/images/bgfiveheroarena.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJumbotronHeader(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.greenAccent,
                                  ),
                                ),
                              )
                            // 🔥 KAWAN: Interseptor UI - Jika juara sudah didapatkan, tampilkan susunan baru sesuai mockup gambar
                            : isTournamentOver
                            ? _buildPodiumJuaraUtama()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color.fromARGB(
                                        97,
                                        10,
                                        23,
                                        71,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Silahkan pilih salah satu arena 1 - 50",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            _showAturanTurnamenBottomSheet();
                                          },
                                          icon: const Icon(
                                            Icons.info_outline_rounded,
                                            color: Colors.lightGreenAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Expanded(
                                    child: arenas.isEmpty
                                        ? Center(
                                            child: Text(
                                              "Belum ada arena yang tersedia kawan.",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: arenas.length,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.only(
                                              bottom: 140,
                                            ),
                                            itemBuilder: (context, index) {
                                              final arena = arenas[index];
                                              final int id = arena['arena_id'];
                                              final String title =
                                                  arena['arena_title'];
                                              final String rawStatus =
                                                  arena['status'] ??
                                                  "waiting...";
                                              final int currentPlayers =
                                                  arena['current_players'] ?? 0;
                                              final int maxPlayers =
                                                  arena['max_players'] ?? 5;
                                              final bool isJoined =
                                                  arena['is_joined'] ?? false;
                                              final int itemBatchId =
                                                  arena['batch_id'] ??
                                                  currentBatchId;

                                              int displayMaxPlayers =
                                                  maxPlayers;
                                              if (currentRound == 3) {
                                                displayMaxPlayers = 5;
                                              }

                                              String displayStatus = rawStatus;
                                              Color statusColor =
                                                  Colors.greenAccent;
                                              bool isFull =
                                                  currentPlayers >=
                                                  displayMaxPlayers;

                                              if (currentRound > 1) {
                                                if (currentRound == 3) {
                                                  displayStatus =
                                                      "Status : SEMIFINAL";
                                                  statusColor = Colors.amber;
                                                } else if (currentRound == 4) {
                                                  displayStatus =
                                                      "Status : GRAND FINAL";
                                                  statusColor =
                                                      Colors.greenAccent;
                                                }
                                              } else if (isFull) {
                                                displayStatus =
                                                    "Status : Full / Berlangsung";
                                                statusColor =
                                                    Colors.orangeAccent;
                                              }

                                              bool isLocked =
                                                  isFull && !isJoined;

                                              if (currentRound > 1 &&
                                                  !isJoined) {
                                                isLocked = true;
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 15.0,
                                                ),
                                                child: _buildArenaCard(
                                                  context: context,
                                                  arenaId: id,
                                                  batchId: itemBatchId,
                                                  title: title,
                                                  status: displayStatus,
                                                  statusColor: statusColor,
                                                  players:
                                                      "Players join $currentPlayers dari $displayMaxPlayers",
                                                  isLocked: isLocked,
                                                ),
                                              );
                                            },
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
        ),
      ),
    );
  }

  // 🏆 KAWAN: Tampilan Widget Podium Juara Utama yang Elegan dan Bebas Error Bounding
  Widget _buildPodiumJuaraUtama() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: AppColors.cardHeaderGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 25),
                  // Lingkaran Foto Profile Hero / Pemenang kawan
                  // 🏆 LINGKARAN FOTO PROFILE SANG JUARA (ANTI-BLANK / ANTI-ERROR)
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(
                        alpha: 0.3,
                      ), // Background cadangan jika gambar gagal kawan
                      border: Border.all(
                        color: const Color(0xFFFDBA74),
                        width: 3,
                      ), // Garis tepi emas soft agar mirip mockup
                      // 🔥 INI KUNCI EFEK GLOW-NYA KAWAN
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFDBA74).withValues(
                            alpha: 0.4,
                          ), // Warna pendaran emas transparan
                          blurRadius:
                              20, // Seberapa nge-blur efek cahayanya (makin besar makin menyebar)
                          spreadRadius:
                              10, // Seberapa jauh pancaran cahayanya keluar dari lingkaran
                          offset: const Offset(
                            0,
                            0,
                          ), // Posisi center agar cahayanya menyebar rata ke segala arah kawan
                        ),
                        // Opsional: Tambah lapisan kedua yang lebih soft & lebar agar efek pendaran lebih halus (sinar gaming)
                        BoxShadow(
                          color: const Color(0xFFEDBA5E).withValues(alpha: 0.2),
                          blurRadius: 35,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],

                      image:
                          (winnerPhoto.isNotEmpty &&
                              winnerPhoto.trim().toLowerCase() != 'null' &&
                              winnerPhoto.trim().toLowerCase() != 'null.png')
                          ? DecorationImage(
                              image: NetworkImage(winnerPhoto),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print(
                                  "Gagal memuat gambar network: $exception",
                                );
                              },
                            )
                          : null, // Jika kosong/null, kita handle tampilannya di bagian child di bawah kawan
                    ),
                    child:
                        (winnerPhoto.isEmpty ||
                            winnerPhoto.trim().toLowerCase() == 'null' ||
                            winnerPhoto.trim().toLowerCase() == 'null.png')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(85),
                            child: Image.asset(
                              'assets/images/winner.png', // Pastikan file ini ada di pubspec.yaml kawan
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // 🔥 JALUR PENYELAMAT TERAKHIR: Jika asset lokal pun typo/gagal, tampilkan Icon default
                                return const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 90,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                );
                              },
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  // Nama Player Juara
                  Text(
                    winnerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle Emas
                  const Text(
                    "SANG JUARA 1",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDBA74),
                    ),
                  ),
                  const Text(
                    "WINNER REWARD",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDBA74),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nominal Hadiah Hijau Cerah kawan
                  const Text(
                    "Rp. 5.000.000",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Deskripsi Turnamen Detail
                  const Text(
                    "TURNAMEN MOBILE LEGEND BY ONE\nMABARSCORE FIVEHERO ARENA\nSEASON 1",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Label Winner Reward
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildJumbotronHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(86, 20, 122, 112),
            Color.fromARGB(93, 8, 56, 50),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hub,
                  color: Colors.orangeAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "FIVEHERO ARENA",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (isTournamentOver) ...[
            const SizedBox(height: 8),
            Column(
              children: [
                const Text(
                  "VICTORY",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDBA74), // Warna Orange Soft kawan
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Turnamen season 1 telah berakhir, turnamen season 2 akan segera dimulai, persiapkan dirimu untuk menjadi sang juara di arena fivehero season 2!",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              currentRound == 1
                  ? "Jadilah juara arena untuk menuju babak berikutnya hingga kamu berada dipuncak arena dan menjadi juara turnamen"
                  : "Selamat bertanding di Babak $currentRound kawan! Tumbangkan jawara lainnya dan rebut gelar juara turnamen!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          isTournamentOver
              ? "Fivehero Arena"
              : currentRound > 1
              ? "Arena - Round $currentRound"
              : "Arena - Round 1",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            int targetBatchId = currentBatchId;
            if (arenas.isNotEmpty && arenas[0]['batch_id'] != null) {
              targetBatchId = arenas[0]['batch_id'];
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JadwalBatchPage(batchId: targetBatchId),
              ),
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              child: Text(
                "semua",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.greenAccent,
                  decorationColor: Colors.greenAccent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArenaCard({
    required BuildContext context,
    required int arenaId,
    required int batchId,
    required String title,
    required String status,
    required Color statusColor,
    required String players,
    required bool isLocked,
  }) {
    // 🔥 KAWAN: Gunakan fungsi penjinak nama string di sini untuk membersihkan title card jika mengandung nama batch mentah
    final String cleanTitle = _cleanBatchName(title);

    return GestureDetector(
      onTap: isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentRound > 1
                        ? "Kamu tidak berpartisipasi di arena ini kawan."
                        : "Maaf kawan, arena ini sudah penuh! Silakan pilih arena lain.",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FiveheroDetailView(
                    arenaId: arenaId,
                    arenaTitle:
                        cleanTitle, // Kirim title yang sudah bersih kawan
                    userCoin: userCoin,
                    batchId: batchId,
                  ),
                ),
              ).then((_) {
                _fetchArenas();
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isLocked
              ? AppColors.cardBg.withValues(alpha: 0.5)
              : const Color.fromARGB(118, 8, 65, 59),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_border_outlined,
                color: isLocked ? Colors.grey : Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanTitle, // Gunakan title yang bersih kawan
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.white54 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    players,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(
                        alpha: isLocked ? 0.25 : 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.north_east_rounded,
              color: isLocked
                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                  : Colors.greenAccent.withValues(alpha: 0.8),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
