import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/fivehero/klasemen_view.dart';

// ==================== 1. MODEL DATA DIKEMBANGKAN SESUAI MATCH DATABASE ====================
class ArenaModel {
  final int arenaId;
  final String arenaName;
  final List<MatchSlotModel> matches;

  ArenaModel({
    required this.arenaId,
    required this.arenaName,
    required this.matches,
  });
}

class MatchSlotModel {
  final int matchNumber;
  final String p1Name;
  final int p1Slot;
  final String p1Image;
  final String p2Name;
  final int p2Slot;
  final String p2Image;
  final bool
  p2IsWaiting; // Untuk mendeteksi Slot 5 yang masih bertanda tanya (?) kawan
  final String waktuMulai;
  final String waktuSelesai;

  MatchSlotModel({
    required this.matchNumber,
    required this.p1Name,
    required this.p1Slot,
    required this.p1Image,
    required this.p2Name,
    required this.p2Slot,
    required this.p2Image,
    this.p2IsWaiting = false,
    required this.waktuMulai,
    required this.waktuSelesai,
  });
}

// ==================== 2. WIDGET HALAMAN UTAMA ====================
class JadwalBatchPage extends StatefulWidget {
  final int batchId;
  const JadwalBatchPage({Key? key, required this.batchId}) : super(key: key);

  @override
  State<JadwalBatchPage> createState() => _JadwalBatchPageState();
}

class _JadwalBatchPageState extends State<JadwalBatchPage> {
  // 🔥 FUNGSI PENARIK DATA REAL DARI DATABASE KAMU KAWAN
  // 🔥 FUNGSI PENARIK DATA TERBARU: Sekali tembak dapat semua arena kawan!
  Future<List<ArenaModel>> fetchJadwalArena() async {
    try {
      final url = Uri.parse(
        "https://donorta.tech/apimabarscore/get_batch_all_matches.php?batch_id=${widget.batchId}",
      );
      final response = await http.get(url);

      // Map untuk menyimpan data real dari API berdasarkan arena_id kawan
      Map<int, ArenaModel> realArenasMap = {};

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['status'] == 'success' && result['data'] != null) {
          List<dynamic> listDataReal = result['data'];

          for (var arenaData in listDataReal) {
            int arenaId = arenaData['arena_id'];
            List<MatchSlotModel> tempMatches = [];
            List<dynamic> matchesData = arenaData['matches'] ?? [];

            for (var mData in matchesData) {
              int mNum = mData['match_number'];
              String p1NameFromApi =
                  mData['player1']?['nickname'] ?? "Nama Player";
              String p2NameFromApi =
                  mData['player2']?['nickname'] ?? "Menunggu...";

              int slotKiri = 1;
              int slotKanan = 2;

              if (mNum == 1) {
                slotKiri = 1;
                slotKanan = 2;
              } else if (mNum == 2) {
                slotKiri = 3;
                slotKanan = 4;
              } else if (mNum == 3) {
                slotKiri = 11;
                slotKanan = 12;
              } else if (mNum == 4) {
                slotKiri = 13;
                slotKanan = 5;
              }

              tempMatches.add(
                MatchSlotModel(
                  matchNumber: mNum,
                  p1Name: p1NameFromApi,
                  p1Slot: slotKiri,
                  p1Image: mData['player1']?['image'] ?? "",
                  p2Name: p2NameFromApi,
                  p2Slot: slotKanan,
                  p2Image: mData['player2']?['image'] ?? "",
                  p2IsWaiting: mNum == 4 && p2NameFromApi == "Menunggu...",
                  waktuMulai: mData['waktu_tanding'] ?? "",
                  waktuSelesai: mData['waktu_selesai'] ?? "",
                ),
              );
            }

            realArenasMap[arenaId] = ArenaModel(
              arenaId: arenaId,
              arenaName: arenaData['arena_name'] ?? "Fivehero Arena $arenaId",
              matches: tempMatches,
            );
          }
        }
      }

      // 🔥 GENERATE TEMPLATE OTOMATIS BERKILAU 1 S/D 50 KAWAN
      List<ArenaModel> final50Arenas = [];

      for (int i = 1; i <= 50; i++) {
        if (realArenasMap.containsKey(i)) {
          // Jika di database sudah ada datanya (seperti Arena 4), masukkan data asli kawan!
          final50Arenas.add(realArenasMap[i]!);
        } else {
          // Jika database kosong, buatkan template default Match 1 s/d 4 kosongan kawan!
          List<MatchSlotModel> templateMatches = [];

          for (int mNum = 1; mNum <= 4; mNum++) {
            int slotKiri = 1;
            int slotKanan = 2;

            if (mNum == 1) {
              slotKiri = 1;
              slotKanan = 2;
            } else if (mNum == 2) {
              slotKiri = 3;
              slotKanan = 4;
            } else if (mNum == 3) {
              slotKiri = 11;
              slotKanan = 12;
            } else if (mNum == 4) {
              slotKiri = 13;
              slotKanan = 5;
            }

            templateMatches.add(
              MatchSlotModel(
                matchNumber: mNum,
                p1Name: mNum == 4
                    ? "Juara M3"
                    : (mNum == 3 ? "Juara M1" : "Nama Player"),
                p1Slot: slotKiri,
                p1Image: "",
                p2Name: mNum == 3 ? "Juara M2" : "Menunggu...",
                p2Slot: slotKanan,
                p2Image: "",
                p2IsWaiting:
                    true, // Biar ikon melingkar oranye (?) muncul rapi kawan
                waktuMulai:
                    "", // Kosong agar otomatis tertulis "Menunggu jadwal..."
                waktuSelesai: "",
              ),
            );
          }

          final50Arenas.add(
            ArenaModel(
              arenaId: i,
              arenaName: "Fivehero Arena $i",
              matches: templateMatches,
            ),
          );
        }
      }

      return final50Arenas; // Kembalikan 50 arena utuh siap tayang kawan!
    } catch (e) {
      debugPrint("Error generate 50 arena kawan: $e");
    }

    return [];
  }

  // Helper formatting jam agar rapi kawan

  String _formatMatchDuration(String? rawStart, String? rawEnd) {
    if (rawStart == null || rawStart.isEmpty) return "";

    const List<String> namaBulan = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];

    try {
      DateTime startUTC = DateTime.parse(rawStart);

      if (!rawStart.endsWith('Z')) {
        startUTC = DateTime.utc(
          startUTC.year,
          startUTC.month,
          startUTC.day,
          startUTC.hour,
          startUTC.minute,
          startUTC.second,
        );
      }

      DateTime startLocal = startUTC.toLocal();
      String startHour = startLocal.hour.toString().padLeft(2, '0');
      String startMin = startLocal.minute.toString().padLeft(2, '0');
      String timeZoneName = startLocal.timeZoneName;

      if (rawEnd != null && rawEnd.isNotEmpty) {
        DateTime endUTC = DateTime.parse(rawEnd);
        if (!rawEnd.endsWith('Z')) {
          endUTC = DateTime.utc(
            endUTC.year,
            endUTC.month,
            endUTC.day,
            endUTC.hour,
            endUTC.minute,
            endUTC.second,
          );
        }
        DateTime endLocal = endUTC.toLocal();

        String endHour = endLocal.hour.toString().padLeft(2, '0');
        String endMin = endLocal.minute.toString().padLeft(2, '0');

        int tgl = endLocal.day;
        String bulan = namaBulan[endLocal.month];
        int tahun = endLocal.year;

        return "$startHour:$startMin - $endHour:$endMin $timeZoneName,\n$tgl $bulan $tahun";
      }

      int tglStart = startLocal.day;
      String bulanStart = namaBulan[startLocal.month];
      int tahunStart = startLocal.year;
      return "$startHour:$startMin $timeZoneName,\n$tglStart $bulanStart $tahunStart";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildButtonKlasemen(),

              // List Utama Arena
              Expanded(
                child: FutureBuilder<List<ArenaModel>>(
                  future: fetchJadwalArena(), // Memanggil fungsi database kawan
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "Belum ada jadwal kawan kawan",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return _buildArenaSection(snapshot.data![index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER APPBAR
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Fivehero batch ${widget.batchId}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // BUTTON KLASEMEN
  Widget _buildButtonKlasemen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF52C47E),
          borderRadius: BorderRadius.circular(10),
        ),
        // Material digunakan agar InkWell bisa bekerja di atas Container/Decoration
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              // Indikator loading bisa ditambahkan di sini jika perlu

              // 🔥 Menggunakan .toString() agar lebih aman dari error tipe data
              final data = await ApiService().getBatchStandings(
                widget.batchId.toString(),
              );

              if (data != null && data['status'] == 'success') {
                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KlasemenView(
                      batchId: widget.batchId.toString(),
                      klasemenData: data['data'], // Kirim data hasil API
                    ),
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal memuat data klasemen")),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lihat Klasemen",
                    style: TextStyle(
                      color: Color(0xFF052924),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF052924),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 3. WIDGET UTAMA PER ARENA ====================
  Widget _buildArenaSection(ArenaModel arena) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          arena.arenaName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // 🔥 KITA MODIFIKASI COLUMN MATCH DI SINI KAWAN
        Column(
          children: arena.matches.asMap().entries.map((entry) {
            int index = entry.key;
            var match = entry.value;

            return Column(
              children: [
                // 1. Tampilkan baris pertandingan kawan
                _buildMatchRow(match),

                // 2. 🔥 DIVIDER PEMISAH ANTAR MATCH kawan
                // Hanya muncul jika pertandingan ini BUKAN pertandingan terakhir di dalam arena
                if (index < arena.matches.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14.0,
                    ), // Jarak atas bawah garis pemisah kawan
                    child: Divider(
                      color: Colors
                          .white10, // Putih tipis transparan biar elegan di latar hijau kawan
                      thickness: 1,
                    ),
                  ),
              ],
            );
          }).toList(),
        ),

        // Jarak penutup di bawah setiap arena kawan
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMatchRow(MatchSlotModel match) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              children: [
                _buildPlayerRow(
                  match.p1Name,
                  match.p1Slot,
                  false,
                  match.p1Image,
                ),
                const SizedBox(height: 12),
                _buildPlayerRow(
                  match.p2Name,
                  match.p2Slot,
                  match.p2IsWaiting,
                  match.p2Image,
                ),
              ],
            ),
          ),

          Container(
            height: 70,
            width: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white30,
          ),

          // KELOMPOK KANAN: Keterangan Jam Jadwal Main Terformat Otomatis Kawan
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Jadwal main",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // 🔥 EKSEKUSI FUNGSI PINTAR FORMAT WAKTU KAMU DI SINI KAWAN
                Text(
                  _formatMatchDuration(
                        match.waktuMulai,
                        match.waktuSelesai,
                      ).isNotEmpty
                      ? _formatMatchDuration(
                          match.waktuMulai,
                          match.waktuSelesai,
                        )
                      : "Menunggu jadwal...",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height:
                        1.3, // Memberi spasi antar baris jika teks wrap ke bawah kawan
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
    String name,
    int slot,
    bool isWaiting,
    String imageUrl,
  ) {
    bool hasImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    // 🔥 LOGIKA PENENTUAN TEKS LABEL DI BAWAH NAMA KAWAN
    String playerLabel = "Player $slot";
    if (slot == 11) {
      playerLabel = "Juara M1";
    } else if (slot == 12) {
      playerLabel = "Juara M2";
    } else if (slot == 13) {
      playerLabel = "Juara M3";
    }

    // 🔥 WARNA BACKDROP AVATAR JIKA TIDAK ADA GAMBAR KAWAN
    Color avatarBgColor = const Color(0xFFFBC02D); // Default Kuning (Ganjil)
    if (isWaiting) {
      avatarBgColor = const Color(0xFFC85A17); // Oranye untuk waiting
    } else if (slot == 2 || slot == 4 || slot == 12) {
      avatarBgColor = const Color(
        0xFF1E88E5,
      ); // Biru untuk posisi kanan (Genap)
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: avatarBgColor,
          backgroundImage: hasImage && !isWaiting
              ? NetworkImage(imageUrl)
              : null,
          child: isWaiting
              ? const Text(
                  "?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                )
              : (!hasImage
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "P",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isWaiting ? Colors.white60 : Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                playerLabel, // 🔥 Teks otomatis berubah dinamis kawan!
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
