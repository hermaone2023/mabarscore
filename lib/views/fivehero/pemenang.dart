import 'dart:convert'; // Tambahkan ini kawan jika belum ada untuk jsonDecode
import 'package:flutter/material.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/fivehero/fivehero_detail_view.dart';
import 'package:mabarscore/views/fivehero/jadwal_batch_page.dart';
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

        // 2. Jika terdeteksi Round 4 (Grand Final selesai / penentuan), panggil API sekali lagi khusus menarik data match kawan
        if (detectedRound == 4) {
          final matchDataRound4 = await ApiService().getArenasData(
            batchId: activeBatchId,
            googleId: currentUserGoogleId,
            round: 4, // 🔥 SUNTIK PARAMETER ROUND DISINI
          );

          // Cek di dalam baris match round 4, apakah sudah ada pemenangnya
          for (var match in matchDataRound4) {
            if (match['pemenang_id'] != null &&
                match['pemenang_id'].toString().isNotEmpty &&
                match['pemenang_id'] != 'NULL') {
              overCheck = true;
              wName = match['pemenang_nama'] ?? "Pro Player 10";
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
          winnerName = wName.isEmpty
              ? "Pro Player 10"
              : wName; // Fallback nama sesuai mockup gambar kawan
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
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

  // 🟢 JUMBOTRON HEADER SEPERTI DI MOCKUP IMAGE_88E32C.PNG
  Widget _buildJumbotronHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4ADE80),
            Color(0xFF047857),
          ], // Gradasi Hijau - Toska cerah kawan
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (isTournamentOver) ...[
            const SizedBox(height: 15),
            const Text(
              "VICTORY",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFDBA74), // Warna Orange Soft kawan
                letterSpacing: 1.2,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              currentRound == 1
                  ? "Jadilah juara arena untuk menuju babak berikutnya hingga kamu berada dipuncak arena dan menjadi dewa player"
                  : "Selamat bertanding di Babak $currentRound kawan! Tumbangkan jawara lainnya dan rebut gelar raja puncak dewa player!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // 🏆 PODIUM UTAMA JUARA SEPERTI DI MOCKUP IMAGE_88E32C.PNG (Bebas Overflow)
  Widget _buildPodiumJuaraUtama() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF0F5257)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Lingkaran Foto Profile Hero / Pemenang kawan
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: winnerPhoto.isNotEmpty
                            ? NetworkImage(winnerPhoto)
                            : const AssetImage(
                                    'assets/images/avatar_fallback.png',
                                  )
                                  as ImageProvider, // Sesuaikan fallback asset kawan jika kosong
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nama Player Juara
                  Text(
                    winnerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
                  const SizedBox(height: 12),
                  // Deskripsi Turnamen Detail
                  const Text(
                    "MABARSCORE FIVEHERO ARENA\nTURNAMEN MOBILE LEGEND 1 VS 1\nSEASON 1",
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
                  const Text(
                    "WINNER REWARD",
                    style: TextStyle(
                      fontSize: 24,
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 🔘 BAR MENU NAVIGATION BAWAH (Pill Abu-Abu 3 Tombol)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(35),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomBarIcon(Icons.emoji_events, isYellow: true),
              _buildBottomBarIcon(Icons.hub, isYellow: false),
              _buildBottomBarIcon(Icons.person, isYellow: false),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBottomBarIcon(IconData icon, {bool isYellow = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF334155), // Background lingkaran tombol gelap kawan
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isYellow ? const Color(0xFFFBBF24) : Colors.blueAccent,
        size: 30,
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
              child: const Text(
                "semua",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.greenAccent,
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
                    arenaTitle: cleanTitle,
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
              : AppColors.cardBg,
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
                    cleanTitle,
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
