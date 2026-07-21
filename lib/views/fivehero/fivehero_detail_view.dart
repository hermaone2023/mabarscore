import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/fivehero/detail_pertandingan_view.dart';
import 'package:mabarscore/views/fivehero/fivehero_payment_view.dart';
import 'package:mabarscore/views/profile/upload_profile_mlbb.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FiveheroDetailView extends StatefulWidget {
  final int arenaId;
  final String arenaTitle;
  final int userCoin;
  final int batchId;

  const FiveheroDetailView({
    Key? key,
    required this.arenaId,
    required this.arenaTitle,
    required this.userCoin,
    required this.batchId,
  }) : super(key: key);

  @override
  State<FiveheroDetailView> createState() => _FiveheroDetailViewState();
}

class _FiveheroDetailViewState extends State<FiveheroDetailView> {
  final ApiService _apiService = ApiService();
  int _coinsBalance = 0;
  String _playerGoogleId = "";

  String? _mlbbId;

  // STATE DINAMIS KAWAN
  List<dynamic> _joinedPlayers = [];
  bool _hasJoined = false;
  bool _alreadyJoinedOther = false;
  bool _isLoadingData = true;
  String _batchMessage = "Memuat status batch...";
  int _currentRound = 1;

  @override
  void initState() {
    super.initState();
    _coinsBalance = widget.userCoin;
    _loadInitialData();
    _initUserSession();
  }

  Future<void> _initUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerGoogleId = prefs.getString('google_id') ?? "";
    });

    // Setelah ID dapat, baru panggil data
    await _refreshUserData();
    _loadInitialData(); // Data arena
  }

  // Panggil fungsi ini untuk sinkronisasi ulang data dari database
  Future<void> _refreshUserData() async {
    if (_playerGoogleId.isEmpty) return; // Jangan panggil jika ID kosong

    try {
      final response = await http.post(
        Uri.parse("https://donorta.tech/apimabarscore/get_profile.php"),
        body: {'google_id': _playerGoogleId},
      );

      debugPrint(
        "Respons API: ${response.body}",
      ); // 🔥 CEK INI DI DEBUG CONSOLE

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("DATA PROFIL DARI API: ${data['data']}");
        if (data['status'] == true) {
          setState(() {
            _mlbbId = data['data']['mlbb_id']
                ?.toString(); // Sini kawan pengisiannya
          });
          debugPrint("MLBB ID berhasil dimuat: $_mlbbId");
        }
      }
    } catch (e) {
      debugPrint("Error load profil: $e");
    }
  }

  // Fungsi sekuensial mengambil session lalu hit API detail kawan
  Future<void> _loadInitialData() async {
    // Memastikan indikator loading aktif dan membersihkan data sisa kawan
    setState(() {
      _isLoadingData = true;
      _joinedPlayers = []; // Amankan dari sisa list batch sebelumnya kawan
      _hasJoined = false;
      _alreadyJoinedOther = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString('user_session');

      if (sessionString != null) {
        final Map<String, dynamic> userData = jsonDecode(sessionString);
        String? currentGoogleId = userData['google_id'];
        _mlbbId = userData['mlbb_id'];

        if (currentGoogleId != null && currentGoogleId.isNotEmpty) {
          _playerGoogleId = currentGoogleId;

          // 1. Tarik saldo koin live kawan
          int balance = await _apiService.getCoinsBalance(
            googleId: currentGoogleId,
          );

          // 2. Tarik detail partisipan arena spesifik sesuai Batch ID kawan!
          final details = await _apiService.getArenaDetails(
            arenaId: widget.arenaId,
            batchId: widget.batchId,
            googleId: currentGoogleId,
          );

          if (!mounted) return;
          setState(() {
            _coinsBalance = balance;
            if (details != null && details['status'] == 'success') {
              _hasJoined = details['has_joined'] ?? false;
              _joinedPlayers = details['players'] ?? [];
              _alreadyJoinedOther =
                  details['already_joined_other_arena'] ?? false;

              // 🔥 KAWAN: Ambil angka round aktif dari backend (default ke 1 jika null)
              _currentRound = details['round'] ?? 1;

              // 🔥 KAWAN: Gabungkan Nama Batch dan Babak secara dinamis
              final String rawBatch = details['nama_batch'] ?? "BATCH-0";
              // Nama variabel TETAP batchName, jadi halaman lain tidak akan error
              final String batchName = rawBatch.contains('-')
                  ? rawBatch.split('-')[1]
                  : rawBatch;

              _batchMessage = "$batchName - BABAK KE-$_currentRound";
            } else {
              // Jika details null atau status dari backend error kawan
              _batchMessage = details?['message'] ?? "Pendaftaran Ditutup";
            }
            _isLoadingData = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoadingData = false);
    } catch (e) {
      print("Error mengambil data di Detail View kawan: $e");
      if (mounted) {
        setState(() {
          _batchMessage = "Gagal memuat data kawan";
          _isLoadingData = false;
        });
      }
    }
  }

  void _handleJoinAction() {
    if (_mlbbId == null || _mlbbId!.trim().isEmpty) {
      // Jika mlbb_id kosong, kunci pendaftaran dan tampilkan perintah upload screenshot lewat AI kawan
      _showIncompleteProfileDialog();
    } else {
      // Jika data aman, lanjutkan ke dialog peraturan yang sudah kamu buat sebelumnya kawan
      _showRulesDialog(context);
    }
  }

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: const Color(0xFF0D4661),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Colors.orangeAccent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Profil Belum Lengkap!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Untuk mengikuti turnamen, kamu wajib melengkapi data Mobile Legends terlebih dahulu dengan mengunggah screenshot profil MLBB kamu kawan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Tutup dialog

                          // Navigasi ke Halaman Upload
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UploadProfileMlbbView(
                                googleId: _playerGoogleId,
                              ),
                            ),
                          );

                          // KUNCI PERBAIKAN: Jika result == true, segarkan data profil DAN data arena
                          if (result == true) {
                            debugPrint("Upload sukses, menyegarkan data...");
                            await _refreshUserData(); // Update _mlbbId
                            await _loadInitialData(); // Update status arena/join
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3AC394),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                        child: const Text(
                          "OK",
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
            image: AssetImage('assets/images/bgdetail.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),

              // 1. CUSTOM APP BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.arenaTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Tombol refresh manual untuk memudahkan user memantau slot kawan
                    IconButton(
                      onPressed: _loadInitialData,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // AREA KONTEN UTAMA DENGAN PULL TO REFRESH kawan
              Expanded(
                child: _isLoadingData
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInitialData,
                        color: Colors.greenAccent,
                        backgroundColor: AppColors.cardBg,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height - 180,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 2. DESKRIPSI ARENA & INDIKATOR BATCH KAWAN
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blueAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.layers_rounded,
                                            color: Colors.blueAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "SEASON ${_batchMessage.toUpperCase()}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Text(
                                      // 🔥 KAWAN: Pembagian 4 kondisi teks spesifik berdasarkan _currentRound (1-4)
                                      _currentRound == 1
                                          ? "Gabung bersama ${widget.arenaTitle}! Kalahkan peserta lain di Babak Kualifikasi ini untuk mengamankan slotmu menuju babak selanjutnya kawan."
                                          : _currentRound == 2
                                          ? "Selamat kawan! Kamu berhasil menembus Babak Perempat Final di ${widget.arenaTitle}. Pertahankan performamu dan tumbangkan lawan untuk melaju ke Semifinal!"
                                          : _currentRound == 3
                                          ? "Langkah luar biasa kawan! Kamu sudah di Babak Semifinal ${widget.arenaTitle}. Tinggal satu langkah lagi menuju panggung tertinggi, amankan tiket Grand Finalmu!"
                                          : "Selamat kawan! Kamu telah memasuki babak GRAND FINAL di ${widget.arenaTitle}. Jadilah Juara sejati dan raih hadiah utama yang menanti di babak pamungkas ini!",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // 3. SUB-JUDUL: Player arena dinamis kawan
                                    Text(
                                      "Player ${_joinedPlayers.length} / ${_currentRound >= 4 ? 2 : 5} Joined",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    // 4. HORIZONTAL LIST CARD PLAYER
                                    SizedBox(
                                      height: 240,
                                      child: _joinedPlayers.isEmpty
                                          ? Center(
                                              child: Text(
                                                "Belum ada player yang bergabung kawan.\nJadilah yang pertama di batch ini!",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount: _joinedPlayers.length,
                                              itemBuilder: (context, index) {
                                                return _buildPlayerCard(
                                                  name:
                                                      _joinedPlayers[index]['name'] ??
                                                      'No Name',
                                                  rank:
                                                      _joinedPlayers[index]['rank'] ??
                                                      'No Rank',

                                                  imageUrl:
                                                      _joinedPlayers[index]['image'] ??
                                                      '',
                                                  badge:
                                                      _joinedPlayers[index]['badge'] ??
                                                      '🛡️',
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),

                                // 5. TOMBOL UTAMA & KONDISIONAL TOMBOL BAGAN KAWAN
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 30.0,
                                    bottom: 20.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if ((_joinedPlayers.length == 5 &&
                                              _hasJoined) ||
                                          _currentRound >= 3) ...[
                                        Container(
                                          width: double.infinity,
                                          height: 55,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetailPertandinganView(
                                                        arenaId: widget.arenaId
                                                            .toString(),
                                                        arenaTitle:
                                                            widget.arenaTitle,
                                                        currentGoogleId:
                                                            _playerGoogleId,
                                                        currentRound:
                                                            _currentRound,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.account_tree_rounded,
                                              color: Colors.black,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.greenAccent[400],
                                              elevation: 6,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            label: const Text(
                                              "LIHAT DETAIL PERTANDINGAN",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      // TOMBOL JOIN / STATUS JOINED KAWAN
                                      // Di babak Grand Final (Round >= 3), kita bisa sembunyikan tombol join ini atau biarkan terkunci
                                      if (_currentRound < 3) ...[
                                        // 1. Kondisi di mana user harus melihat status (Text saja)
                                        if (_hasJoined ||
                                            _alreadyJoinedOther ||
                                            _batchMessage.contains("Ditutup") ||
                                            _joinedPlayers.length >= 5)
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 15.0,
                                                  ),
                                              child: Text(
                                                _hasJoined
                                                    ? "Kamu tergabung di arena ini"
                                                    : _alreadyJoinedOther
                                                    ? "Kamu telah terdaftar di arena lain"
                                                    : _batchMessage.contains(
                                                        "Ditutup",
                                                      )
                                                    ? "PENDAFTARAN DITUTUP"
                                                    : "ARENA PENUH",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          )
                                        // 2. Kondisi di mana user bisa melakukan Join (Tombol)
                                        else
                                          SizedBox(
                                            width: double.infinity,
                                            height: 60,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _handleJoinAction(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.cardBg,
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                              child: Text(
                                                "Join ${widget.arenaTitle.toLowerCase()}",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  // ==================== FUNGSIONAL POP-UP DIALOG KETENTUAN ====================
  void _showRulesDialog(BuildContext context) {
    bool isAgreed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              actionsPadding: const EdgeInsets.only(
                bottom: 16,
                left: 16,
                right: 16,
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "KETENTUAN ARENA",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[300],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.amber, thickness: 0.5),
                    const SizedBox(height: 8),
                    _buildRulePoint(
                      icon: Icons.shuffle_rounded,
                      text:
                          "Setelah 5 peserta lengkap, sistem otomatis mengacak nomor urut (1-5) secara adil untuk menentukan bagan tanding.",
                    ),
                    const SizedBox(height: 12),
                    _buildRulePoint(
                      icon: Icons.workspace_premium_rounded,
                      text:
                          "Player yang mendapat Nomor Urut 5 diuntungkan langsung masuk ke babak FINAL (Menunggu Juara Match 3).",
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "ESTIMASI BAGAN ARENA:",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white60,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "• Match 1 : Player 1 vs Player 2",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            "• Match 2 : Player 3 vs Player 4",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            "• Match 3 : Pemenang M1 vs Pemenang M2",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Text(
                            "• FINAL    : Pemenang M3 vs Player 5 (Slot Acak)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.white60),
                      child: CheckboxListTile(
                        title: const Text(
                          "Saya mengerti dan menyetujui sistem pengacakan bagan ini kawan.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        value: isAgreed,
                        activeColor: Colors.amber,
                        checkColor: Colors.black,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isAgreed = value ?? false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isAgreed) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FiveheroPaymentView(
                                  arenaId: widget.arenaId,
                                  arenaTitle: widget.arenaTitle,
                                  userCoin: _coinsBalance,
                                  googleId: _playerGoogleId,
                                  batchId: widget
                                      .batchId, // 🔥 Tambahkan baris ini kawan!
                                ),
                              ),
                            ).then((_) {
                              if (mounted) {
                                _loadInitialData();
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Wajib mencentang persetujuan ketentuan kawan!",
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAgreed
                              ? Colors.amber
                              : Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Setuju",
                          style: TextStyle(
                            color: isAgreed ? Colors.black : Colors.white30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRulePoint({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.amber[200], size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required String imageUrl,
    required String rank,
    required String badge,
  }) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 9,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(badge, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Image.asset('assets/images/rank.png', width: 20),
              const SizedBox(width: 4),
              Text(
                rank,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Colors.black38,
      width: double.infinity,
      child: const Icon(Icons.person, color: Colors.white30, size: 40),
    );
  }
}
