import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:mabarscore/core/constants/app_colors.dart';
import 'dart:convert';

import 'package:mabarscore/views/fivehero/fivehero_arena_chats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:shared_preferences/shared_preferences.dart';

class DetailPertandinganView extends StatefulWidget {
  final String arenaId;
  final String arenaTitle;
  final String currentGoogleId; // Google ID user login
  final int currentRound;

  const DetailPertandinganView({
    Key? key,
    required this.arenaId,
    required this.arenaTitle,
    required this.currentGoogleId,
    required this.currentRound,
  }) : super(key: key);

  @override
  State<DetailPertandinganView> createState() => _DetailPertandinganViewState();
}

class _DetailPertandinganViewState extends State<DetailPertandinganView> {
  bool _isLoading = true;
  Map<String, dynamic> _matchData = {};
  late int
  _currentRound; // 🔥 Gunakan late agar diinisialisasi dari widget di awal

  // 🔥 Ubah parameter agar menerima nama file String dengan benar
  Future<void> _startMainRecording(String fileName) async {
    await Permission.storage.request();
    await Permission.microphone.request();
    await Permission.notification.request();

    try {
      // 🔥 Perbaikan konfigurasi tanpa parameter 'icon' yang salah
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'mabarscore_recording_channel',
          channelName: 'MabarScore Recording Channel',
          channelDescription: 'Channel untuk perekaman layar pertandingan',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      // 🔥 Memulai service tanpa callback error 'startCallback' yang tidak terdefinisi
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: 'MabarScore Sedang Merekam',
          notificationText:
              'Perekaman pertandingan sedang berjalan di latar belakang.',
        );
      }

      print("Mulai mencoba merekam layar dengan nama: $fileName");

      bool started = await FlutterScreenRecording.startRecordScreen(fileName);

      if (started) {
        setState(() {});
        print("Perekaman layar utama berhasil dimulai!");
      } else {
        print("Uji Coba: Perekaman ditolak atau gagal dimulai oleh sistem.");
      }
    } catch (e) {
      print("Gagal memulai perekaman utama (Exception): $e");
    }
  }

  Future<void> _stopMainRecording() async {
    try {
      print("Mengehentikan perekaman utama dan mengambil path video...");

      final prefs = await SharedPreferences.getInstance();

      int? arenaId = prefs.getInt('match_arena_id');
      int? batchId = prefs.getInt('match_batch_id');
      int? round = prefs.getInt('match_round');
      int? matchNumber = prefs.getInt('match_number');

      if (arenaId == null || batchId == null || matchNumber == null) {
        print("Gagal: Parameter unik match tidak lengkap di sesi aktif!");
        return;
      }

      String path = await FlutterScreenRecording.stopRecordScreen;
      print("Path video hasil rekaman: '$path'");

      // Hentikan foreground service karena perekaman sudah selesai
      await FlutterForegroundTask.stopService();

      if (path.isEmpty) {
        print("Gagal: Path video kosong dari sistem!");
        return;
      }

      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putVideo(path, album: "MabarScore");

      // 🔥 UPLOAD KE SERVER
      await _uploadVideoToServer(
        arenaId: arenaId,
        batchId: batchId,
        round: round ?? 1,
        matchNumber: matchNumber,
        videoPath: path,
      );

      await prefs.remove('match_arena_id');
      await prefs.remove('match_batch_id');
      await prefs.remove('match_round');
      await prefs.remove('match_number');
    } catch (e) {
      print("Gagal menghentikan atau menyimpan rekaman (Exception): $e");
      await FlutterForegroundTask.stopService();
    }
  }

  // Fungsi helper HTTP Multipart Upload
  Future<void> _uploadVideoToServer({
    required int arenaId,
    required int batchId,
    required int round,
    required int matchNumber,
    required String videoPath,
  }) async {
    try {
      print("Mengunggah video pertandingan ke server...");

      var uri = Uri.parse(
        'https://donorta.tech/apimabarscore/upload_match_video.php',
      );

      var request = http.MultipartRequest('POST', uri);

      // Kirimkan parameter pengenal baris tabel sebagai fields
      request.fields['arena_id'] = arenaId.toString();
      request.fields['batch_id'] = batchId.toString();
      request.fields['round'] = round.toString();
      request.fields['match_number'] = matchNumber.toString();

      // File video dikirim dengan key 'video_file'
      request.files.add(
        await http.MultipartFile.fromPath('video_file', videoPath),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Response Status Code: ${response.statusCode}");
      print("Response Body Mentah: '${response.body}'");

      if (response.statusCode == 200) {
        print(
          "SUKSES! Video berhasil di-upload dan tersimpan di kolom video_pertandingan.",
        );
      } else {
        print("Gagal upload ke server: ${response.body}");
      }
    } catch (e) {
      print("Error saat mengunggah video ke server: $e");
    }
  }

  Future<void> _startMatchAndShowOverlay({
    required int arenaId,
    required int batchId,
    required int round,
    required int matchNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simpan parameter komposit pengenal baris match
      await prefs.setInt('match_arena_id', arenaId);
      await prefs.setInt('match_batch_id', batchId);
      await prefs.setInt('match_round', round);
      await prefs.setInt('match_number', matchNumber);
      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      if (!isGranted) {
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      bool isActive = await FlutterOverlayWindow.isActive();
      if (!isActive) {
        await FlutterOverlayWindow.showOverlay(
          height: 660,
          width: 550, // 💡 Kunci lebar di 360 agar pas dan tidak overflow
          alignment: OverlayAlignment.centerRight,
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.none,
          enableDrag: true,
        );
      }
    } catch (e) {
      print("Error memunculkan overlay: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _currentRound =
        widget.currentRound; // 🔥 Ambil babak awal dari parameter widget kawan
    _fetchMatchDetails();
    // 🔥 Pantau sinyal START dan STOP secara bersamaan di Activity utama
    Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      bool shouldStart = prefs.getBool('start_recording_signal') ?? false;
      bool shouldStop = prefs.getBool('stop_recording_signal') ?? false;

      if (shouldStart) {
        await prefs.setBool('start_recording_signal', false);
        print("Sinyal START terdeteksi di Activity utama!");
        String fileName = "MabarScore_${DateTime.now().millisecondsSinceEpoch}";
        await _startMainRecording(fileName);
      }

      if (shouldStop) {
        await prefs.setBool('stop_recording_signal', false);
        print(
          "Sinyal STOP terdeteksi di Activity utama! Mengeksekusi _stopMainRecording()...",
        );
        await _stopMainRecording(); // 🔥 Dijalankan di sini agar plugin terbaca dengan normal!
      }
    });
  }

  Future<void> _fetchMatchDetails() async {
    try {
      // Pastikan indikator loading aktif saat melakukan refresh kawan
      if (!_isLoading) {
        setState(() => _isLoading = true);
      }

      final url = Uri.parse(
        "https://donorta.tech/apimabarscore/get_arena_match_details.php?arena_id=${widget.arenaId}&round=$_currentRound", // 🔥 Gunakan variabel state lokal yang dinamis kawan
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _matchData = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetch match: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🔥 Fungsi pintar mendeteksi ID lawan chat real-time berdasarkan Match aktif user
  String _cariGoogleIdLawan() {
    if (_matchData.isEmpty) return "";

    String myId = widget.currentGoogleId;

    // Jika masuk Grand Final, langsung prioritaskan cek Match 4 saja kawan agar cepat!
    if (_currentRound >= 3) {
      if (_matchData['match4'] == null) return "BOT_MEDIATOR";
      String? m4p1 = _matchData['match4']?['player1']?['google_id'];
      String? m4p2 = _matchData['match4']?['player2']?['google_id'];
      if (myId == m4p1 && m4p2 != null) return m4p2;
      if (myId == m4p2 && m4p1 != null) return m4p1;
      return "BOT_MEDIATOR";
    }

    // 1. Cek Match 1 kawan
    if (_matchData['match1'] != null) {
      String? p1 = _matchData['match1']?['player1']?['google_id'];
      String? p2 = _matchData['match1']?['player2']?['google_id'];
      if (myId == p1) return p2 ?? "";
      if (myId == p2) return p1 ?? "";
    }

    // 2. Cek Match 2 kawan
    if (_matchData['match2'] != null) {
      String? p3 = _matchData['match2']?['player1']?['google_id'];
      String? p4 = _matchData['match2']?['player2']?['google_id'];
      if (myId == p3) return p4 ?? "";
      if (myId == p4) return p3 ?? "";
    }

    // 3. Cek Match 3 kawan (Semifinal)
    if (_matchData['match3'] != null) {
      String? m3p1 = _matchData['match3']?['player1']?['google_id'];
      String? m3p2 = _matchData['match3']?['player2']?['google_id'];
      if (myId == m3p1 && m3p2 != null) return m3p2;
      if (myId == m3p2 && m3p1 != null) return m3p1;
    }

    return "BOT_MEDIATOR";
  }

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

        return "$startHour:$startMin - $endHour:$endMin $timeZoneName $tgl $bulan $tahun";
      }

      int tglStart = startLocal.day;
      String bulanStart = namaBulan[startLocal.month];
      int tahunStart = startLocal.year;
      return "$startHour:$startMin $timeZoneName $tglStart $bulanStart $tahunStart";
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
          image: DecorationImage(
            image: AssetImage('assets/images/bgbraket.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Utama
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      // Menentukan judul header atas secara dinamis
                      _currentRound == 1
                          ? "Babak Kualifikasi"
                          : _currentRound == 2
                          ? "Babak Perempat Final"
                          : _currentRound == 3
                          ? "Babak Semifinal"
                          : "Grand Final Utama",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMatchDetails,
                        color: Colors.greenAccent,
                        backgroundColor: const Color(0xFF145347),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),

                              // Sub-Header Dinamis beserta sisa slot player kawan
                              Text(
                                _currentRound == 1
                                    ? "Grup: ${widget.arenaTitle} - Kualifikasi (250 Player)"
                                    : _currentRound == 2
                                    ? "Grup: ${widget.arenaTitle} - Perempat Final (50 Player)"
                                    : _currentRound == 3
                                    ? "Grup: ${widget.arenaTitle} - Semifinal (10 Player)"
                                    : "Grup: ${widget.arenaTitle} - Grand Final (Top 2)",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ========================================================
                              // 💥 SELEKSI DINAMIS: Render Match jika datanya tidak null kawan!
                              // ========================================================

                              // --- MATCH 1 ---
                              if (_matchData['match1'] != null) ...[
                                _buildMatchHeader(
                                  "MATCH 1(M1): SELEKSI GRUP",
                                  _formatMatchDuration(
                                    _matchData['match1']?['waktu_tanding'],
                                    _matchData['match1']?['waktu_selesai'],
                                  ),
                                ),
                                _buildMatchCard(
                                  pemenangId:
                                      _matchData['match1']?['pemenang_id'],
                                  labelPlayerLeft: "Player 1",
                                  googleIdLeft:
                                      _matchData['match1']?['player1']?['google_id'],
                                  namePlayerLeft:
                                      _matchData['match1']?['player1']?['nickname'],
                                  imgPlayerLeft:
                                      _matchData['match1']?['player1']?['image'],
                                  labelPlayerRight: "Player 2",
                                  googleIdRight:
                                      _matchData['match1']?['player2']?['google_id'],
                                  namePlayerRight:
                                      _matchData['match1']?['player2']?['nickname'],
                                  imgPlayerRight:
                                      _matchData['match1']?['player2']?['image'],
                                  statusSiapLeft: int.tryParse(
                                    _matchData['match1']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  statusSiapRight: int.tryParse(
                                    _matchData['match1']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  matchItemData: _matchData['match1'],
                                ),
                                const SizedBox(height: 20),
                              ],

                              // --- MATCH 2 ---
                              if (_matchData['match2'] != null) ...[
                                _buildMatchHeader(
                                  "MATCH 2(M2): SELEKSI GRUP",
                                  _formatMatchDuration(
                                    _matchData['match2']?['waktu_tanding'],
                                    _matchData['match2']?['waktu_selesai'],
                                  ),
                                ),
                                _buildMatchCard(
                                  pemenangId:
                                      _matchData['match2']?['pemenang_id'],
                                  labelPlayerLeft: "Player 3",
                                  googleIdLeft:
                                      _matchData['match2']?['player1']?['google_id'],
                                  namePlayerLeft:
                                      _matchData['match2']?['player1']?['nickname'],
                                  imgPlayerLeft:
                                      _matchData['match2']?['player1']?['image'],
                                  labelPlayerRight: "Player 4",
                                  googleIdRight:
                                      _matchData['match2']?['player2']?['google_id'],
                                  namePlayerRight:
                                      _matchData['match2']?['player2']?['nickname'],
                                  imgPlayerRight:
                                      _matchData['match2']?['player2']?['image'],
                                  statusSiapLeft: int.tryParse(
                                    _matchData['match2']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  statusSiapRight: int.tryParse(
                                    _matchData['match2']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  matchItemData: _matchData['match2'],
                                ),
                                const SizedBox(height: 20),
                              ],

                              // --- MATCH 3 (Status Berlangsung dalam JSON) ---
                              if (_matchData['match3'] != null) ...[
                                _buildMatchHeader(
                                  _currentRound == 4
                                      ? "MATCH 3(M3): PEREBUTAN JUARA 3 (Jika ada)"
                                      : "MATCH 3(M3): PENENTUAN FINALIS GRUP",
                                  _formatMatchDuration(
                                    _matchData['match3']?['waktu_tanding'],
                                    _matchData['match3']?['waktu_selesai'],
                                  ),
                                ),
                                _buildMatchCard(
                                  pemenangId:
                                      _matchData['match3']?['pemenang_id'],
                                  labelPlayerLeft: "Juara M1",
                                  googleIdLeft:
                                      _matchData['match3']?['player1']?['google_id'],
                                  namePlayerLeft:
                                      _matchData['match3']?['player1']?['nickname'],
                                  imgPlayerLeft:
                                      _matchData['match3']?['player1']?['image'],
                                  labelPlayerRight: "Juara M2",
                                  googleIdRight:
                                      _matchData['match3']?['player2']?['google_id'],
                                  namePlayerRight:
                                      _matchData['match3']?['player2']?['nickname'],
                                  imgPlayerRight:
                                      _matchData['match3']?['player2']?['image'],
                                  statusSiapLeft: int.tryParse(
                                    _matchData['match3']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  statusSiapRight: int.tryParse(
                                    _matchData['match3']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  matchItemData: _matchData['match3'],
                                ),
                                const SizedBox(height: 20),
                              ],

                              // --- MATCH 4 (Player 1 Null / Belum Mulai dalam JSON) ---
                              if (_matchData['match4'] != null) ...[
                                _buildMatchHeader(
                                  _currentRound == 4
                                      ? "PERTANDINGAN PUNCAK: PENENTUAN JUARA UTAMA"
                                      : "MATCH 4(M4): FINAL ARENA GRUP",
                                  _formatMatchDuration(
                                    _matchData['match4']?['waktu_tanding'],
                                    _matchData['match4']?['waktu_selesai'],
                                  ),
                                ),
                                _buildMatchCard(
                                  pemenangId:
                                      _matchData['match4']?['pemenang_id'],
                                  labelPlayerLeft: _currentRound == 4
                                      ? "Finalis 1"
                                      : "Juara M3",
                                  googleIdLeft:
                                      _matchData['match4']?['player1']?['google_id'], // Aman walau bernilai null
                                  namePlayerLeft:
                                      _matchData['match4']?['player1']?['nickname'], // Aman walau bernilai null
                                  imgPlayerLeft:
                                      _matchData['match4']?['player1']?['image'], // Aman walau bernilai null
                                  labelPlayerRight: _currentRound == 4
                                      ? "Finalis 2"
                                      : "Player 5",
                                  googleIdRight:
                                      _matchData['match4']?['player2']?['google_id'],
                                  namePlayerRight:
                                      _matchData['match4']?['player2']?['nickname'],
                                  imgPlayerRight:
                                      _matchData['match4']?['player2']?['image'],
                                  isGrandFinal: true,
                                  statusSiapLeft: int.tryParse(
                                    _matchData['match4']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  statusSiapRight: int.tryParse(
                                    _matchData['match4']?['status_kesiapan']
                                            .toString() ??
                                        '0',
                                  ),
                                  matchItemData: _matchData['match4'],
                                ),
                                const SizedBox(height: 20),
                              ],
                              const SizedBox(height: 35),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader(String title, String matchTime) {
    bool hasTime = matchTime.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: hasTime ? Colors.greenAccent : Colors.white38,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                hasTime
                    ? "Jadwal: $matchTime"
                    : "Jadwal: Menunggu babak sebelumnya",
                style: TextStyle(
                  color: hasTime ? Colors.greenAccent : Colors.white38,
                  fontSize: 11,
                  fontWeight: hasTime ? FontWeight.w500 : FontWeight.normal,
                  fontStyle: hasTime ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard({
    String? pemenangId,
    required String labelPlayerLeft,
    String? googleIdLeft,
    String? namePlayerLeft,
    String? imgPlayerLeft,
    required String labelPlayerRight,
    String? googleIdRight,
    String? namePlayerRight,
    String? imgPlayerRight,
    bool isGrandFinal = false,
    int? statusSiapLeft,
    int? statusSiapRight,
    required Map<String, dynamic> matchItemData,
  }) {
    // 1. Tentukan siapa pemain di match ini berdasarkan google_id
    bool isUserLeft = widget.currentGoogleId == googleIdLeft;
    bool isUserRight = widget.currentGoogleId == googleIdRight;
    bool isParticipant = isUserLeft || isUserRight;

    // 2. Tentukan siapa ID lawannya
    String idLawan = isUserLeft ? (googleIdRight ?? '') : (googleIdLeft ?? '');

    // 3. Ambil status match & status kesiapan langsung dari key JSON
    String statusMatch = matchItemData['status_match'] ?? 'belum mulai';
    bool matchSelesai =
        statusMatch == 'selesai' ||
        (pemenangId != null && pemenangId.isNotEmpty);
    bool matchBerlangsung = statusMatch == 'berlangsung';

    // Ambil status_kesiapan (konversi ke int dengan aman, default 0)
    int statusKesiapan =
        int.tryParse(matchItemData['status_kesiapan']?.toString() ?? '0') ?? 0;
    bool isSudahSepakat = statusKesiapan == 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGrandFinal
              ? [
                  Colors.amber.withValues(alpha: 0.25),
                  Colors.purple.withValues(alpha: 0.35),
                ]
              : [
                  const Color.fromARGB(28, 20, 122, 112),
                  const Color.fromARGB(151, 8, 56, 50),
                ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isGrandFinal
              ? Colors.amberAccent.withValues(alpha: 0.5)
              : const Color.fromARGB(168, 33, 149, 243),
          width: isGrandFinal ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Row Utama Player Kiri & Kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlayerSlot(
                labelPlayerLeft,
                namePlayerLeft,
                imgPlayerLeft,
                googleIdLeft,
                pemenangId,
                Colors.amber,
                isGrandFinal,
                statusSiapLeft,
              ),
              const Text(
                "VS",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Colors.white60,
                ),
              ),
              _buildPlayerSlot(
                labelPlayerRight,
                namePlayerRight,
                imgPlayerRight,
                googleIdRight,
                pemenangId,
                Colors.blueAccent,
                isGrandFinal,
                statusSiapRight,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          // 🔥 TOMBOL KESEPAKATAN / MULAI TANDING
          // 🔥 TOMBOL KESEPAKATAN / MULAI TANDING
          GestureDetector(
            onTap: () async {
              // 🛡️ 1. VALIDASI UTAMA: Apakah user adalah peserta sah? Jika bukan, langsung TOLAK!
              if (!isParticipant) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Akses ditolak! Anda bukan peserta yang bertanding di match ini.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // 2. Cek apakah match sudah selesai
              if (matchSelesai) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Match ini telah selesai! Kesepakatan ditutup.',
                    ),
                    backgroundColor: Colors.grey,
                  ),
                );
                return;
              }

              // 3. Cek apakah match sedang berlangsung
              if (!matchBerlangsung) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Match belum dimulai atau belum waktunya bertanding!',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // 4. Apakah slot player lengkap
              if (googleIdLeft == null ||
                  googleIdRight == null ||
                  googleIdLeft.isEmpty ||
                  googleIdRight.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lawan tanding di match ini belum lengkap/tersedia!',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // 5. Pastikan ID lawan valid
              if (idLawan.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID lawan tanding tidak valid!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // 6. Jika sudah sepakat sebagai peserta, jalankan mulai tanding & overlay
              if (isSudahSepakat) {
                final int arenaId =
                    int.tryParse(
                      matchItemData['arena_id']?.toString() ?? '0',
                    ) ??
                    0;
                final int batchId =
                    int.tryParse(
                      matchItemData['batch_id']?.toString() ?? '0',
                    ) ??
                    0;
                final int round =
                    int.tryParse(matchItemData['round']?.toString() ?? '1') ??
                    1;
                final int matchNumber =
                    int.tryParse(
                      matchItemData['match_number']?.toString() ?? '0',
                    ) ??
                    0;

                await _startMatchAndShowOverlay(
                  arenaId: arenaId,
                  batchId: batchId,
                  round: round,
                  matchNumber: matchNumber,
                );
                return;
              }

              // Jika belum sepakat, buka halaman chat kesepakatan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FiveheroChatView(
                    arenaId: widget.arenaId,
                    currentGoogleId: widget.currentGoogleId,
                    opponentGoogleId: idLawan,
                    matchData: matchItemData,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                // 🎨 Perbaikan Warna Berdasarkan Kepemilikan Match (isParticipant)
                color: !isParticipant
                    ? Colors.grey.withValues(alpha: 0.1)
                    : (matchSelesai || !matchBerlangsung
                          ? Colors.grey.withValues(alpha: 0.15)
                          : (isSudahSepakat
                                ? const Color.fromARGB(
                                    255,
                                    18,
                                    120,
                                    164,
                                  ).withValues(alpha: 0.25)
                                : const Color(0xFF145347))),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isParticipant
                      ? Colors.white12
                      : (matchSelesai || !matchBerlangsung
                            ? Colors.white24
                            : (isSudahSepakat
                                  ? const Color.fromARGB(
                                      255,
                                      128,
                                      255,
                                      0,
                                    ).withValues(alpha: 0.7)
                                  : Colors.greenAccent.withValues(alpha: 0.6))),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isParticipant
                          ? Icons.lock_outline
                          : (matchSelesai
                                ? Icons.check_circle_outline
                                : (!matchBerlangsung
                                      ? Icons.timer_outlined
                                      : (isSudahSepakat
                                            ? Icons.play_arrow
                                            : Icons.handshake))),
                      color: !isParticipant
                          ? Colors.white38
                          : (matchSelesai || !matchBerlangsung
                                ? Colors.white38
                                : (isSudahSepakat
                                      ? const Color.fromARGB(255, 149, 255, 0)
                                      : Colors.greenAccent)),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !isParticipant
                          ? 'Bukan Match Anda'
                          : (matchSelesai
                                ? 'Match Telah Selesai'
                                : (!matchBerlangsung
                                      ? 'Match Belum Dimulai'
                                      : (isSudahSepakat
                                            ? 'Mulai Tanding'
                                            : 'Buat Kesepakatan Match Ini'))),
                      style: TextStyle(
                        color: !isParticipant
                            ? Colors.white38
                            : (matchSelesai || !matchBerlangsung
                                  ? Colors.white38
                                  : (isSudahSepakat
                                        ? const Color.fromARGB(255, 81, 255, 0)
                                        : Colors.greenAccent)),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(
    String label,
    String? name,
    String? imgUrl,
    String? googleId,
    String? pemenangId,
    Color fallbackColor,
    bool isGrandFinal,
    int? statusSiap, // 🔥 Tambahkan parameter ini
  ) {
    bool isWaiting = (name == null || name.isEmpty);
    bool matchSudahSelesai = (pemenangId != null && pemenangId.isNotEmpty);
    bool isPemenang = (matchSudahSelesai && googleId == pemenangId);
    bool isGugur =
        (matchSudahSelesai && googleId != pemenangId && googleId != null);

    const Color warnaGugurMenyala = Color(0xFFFF6B6B);

    return Opacity(
      opacity: isGugur ? 0.55 : 1.0,
      child: Column(
        children: [
          // ... (Bagian Stack CircleAvatar tetap sama, tidak perlu diubah) ...
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPemenang
                        ? const Color(0xFF083832)
                        : (isGugur ? warnaGugurMenyala : Colors.transparent),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: isWaiting
                      ? Colors.grey.shade800
                      : fallbackColor,
                  backgroundImage:
                      (!isWaiting && imgUrl != null && imgUrl.isNotEmpty)
                      ? NetworkImage(imgUrl)
                      : null,
                  child: isWaiting
                      ? const Text(
                          "?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              if (isPemenang)
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 8,
                  right: -60,
                  child: Icon(
                    Icons.emoji_events,
                    color: isGrandFinal
                        ? const Color.fromARGB(255, 0, 255, 0)
                        : Colors.amber,
                    size: 35,
                  ),
                ),
              if (isGugur)
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 8,
                  right: -60,
                  child: Icon(Icons.cancel, color: warnaGugurMenyala, size: 35),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isWaiting
                ? "(Menunggu Pemenang)"
                : (isPemenang && isGrandFinal ? "👑 $name" : "$name"),
            style: TextStyle(
              color: isPemenang
                  ? const Color.fromARGB(255, 9, 255, 0)
                  : (isWaiting ? Colors.white38 : Colors.white70),
              fontSize: 11,
              decoration: isGugur
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          // 🔥 TAMBAHKAN TAMPILAN STATUS SIAP DI SINI
          if (!isWaiting)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (statusSiap == 1)
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (statusSiap == 1) ? "Siap Tanding" : "Belum Siap",
                style: TextStyle(
                  color: (statusSiap == 1)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
