import 'package:flutter/material.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/fivehero/jadwal_batch_page.dart';

class MatchFinishedScreen extends StatefulWidget {
  const MatchFinishedScreen({super.key});

  @override
  State<MatchFinishedScreen> createState() => _MatchFinishedScreenState();
}

class _MatchFinishedScreenState extends State<MatchFinishedScreen> {
  int userCoin = 0;
  List<dynamic> arenas = [];
  int currentBatchId = 1;
  int currentRound = 1; // 🔥 KAWAN: State mencatat babak aktif saat ini
  String currentUserGoogleId = "";

  // 🔥 KAWAN: Tambahan state penampung interceptor podium juara
  bool isTournamentOver = false;
  String winnerName = "";
  String winnerPhoto = "";
  String winnerGoogleId = "";

  Future<void> _fetchArenas() async {
    try {
      if (!mounted) return;
      setState(() {});

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
        });
      }
    } catch (e) {
      print("Gagal memuat ulang data arena kawan: $e");
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  initState() {
    super.initState();
    _fetchArenas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ikon Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: Colors.tealAccent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Judul
                  const Text(
                    "Pertandingan Selesai",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Divider(
                    color: Colors.white.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Pesan Pemberitahuan
                  const Text(
                    "Pertandingan kamu telah selesai dan rekaman layar berhasil diamankan serta di-upload ke server.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Tombol Lihat Hasil ke DetailPertandinganView
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Ambil kembali data parameter pertandingan yang tersimpan sebelumnya
                        int targetBatchId = currentBatchId;
                        if (arenas.isNotEmpty &&
                            arenas[0]['batch_id'] != null) {
                          targetBatchId = arenas[0]['batch_id'];
                        }
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JadwalBatchPage(batchId: targetBatchId),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Lihat Hasil",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
