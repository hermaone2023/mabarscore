import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/views/fivehero/detail_gambar_view.dart';
import 'package:url_launcher/url_launcher.dart';

class FiveheroChatView extends StatefulWidget {
  final String arenaId;
  final String currentGoogleId; // ID User yang sedang login kawan
  final String opponentGoogleId; // ID Lawan yang dipilih dari dropdown kawan
  final Map<String, dynamic> matchData;
  final int round; // 🔥 Tambahkan ini kawan
  final int matchNumber; // 🔥 Tambahkan ini kawan

  const FiveheroChatView({
    Key? key,
    required this.arenaId,
    required this.currentGoogleId,
    required this.opponentGoogleId,
    required this.matchData,
    required this.round, // 🔥 Wajibkan diisi saat dipanggil
    required this.matchNumber, // 🔥 Wajibkan diisi saat dipanggil
  }) : super(key: key);

  @override
  _FiveheroChatViewState createState() => _FiveheroChatViewState();
}

class _FiveheroChatViewState extends State<FiveheroChatView> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _chatMessages = [];
  Timer? _chatTimer;
  bool _isLoading = true;
  String? _selectedHeroCategory;
  bool _formSiapTanding = false;
  String? _selectedOpponentId;

  // Sesuaikan domain URL direktori gambar di server kawan
  final String _imageBaseUrl =
      "https://donorta.tech/apimabarscore/uploads/chats/";

  // Contoh fungsi pengiriman ke PHP
  Future<void> _simpanKesepakatanKeServer() async {
    final url = Uri.parse(
      'https://donorta.tech/apimabarscore/simpan_kesepakatan.php',
    );

    try {
      // 1. Ambil batch_id, round, dan match_number langsung secara presisi dari widget.matchData
      String batchId = widget.matchData['batch_id']?.toString() ?? "1";
      String round = widget.matchData['round']?.toString() ?? "1";
      String matchNumber = widget.matchData['match_number']?.toString() ?? "1";

      print(
        "DEBUG KIRIM -> Batch: $batchId, Round: $round, Match No: $matchNumber",
      );

      // 2. Kirim data ke server PHP
      final response = await http.post(
        url,
        body: {
          'id_home': widget.currentGoogleId,
          'id_away': widget.opponentGoogleId,
          'kategori_hero': _selectedHeroCategory ?? '',
          'status': 'SEPAKAT SIAP TANDING',
          'arena_id': widget.arenaId.toString(),
          'batch_id': batchId,
          'round': round,
          'match_number':
              matchNumber, // Sekarang dijamin bernilai 3 (atau sesuai match yang diklik)
        },
      );

      print("RAW RESPONSE PHP: ${response.body}");

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        print("Berhasil simpan ke DB: ${data['message']}");
      } else {
        print("Gagal simpan ke DB: ${data['message']}");
      }
    } catch (e) {
      print("Terjadi kesalahan koneksi / parsing: $e");
    }
  }

  void _tampilkanDialogKesepakatanDanKonfirmasi() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D4661),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Kesepakatan & Aturan Tanding MLBB 1 vs 1",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "Pilih Kategori Hero Kesepakatan:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedHeroCategory,
                          hint: const Text(
                            "Pilih Kategori Hero",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          dropdownColor: const Color(0xFF0C4A60),
                          isExpanded: true,
                          items: ['Fighter', 'Assassin', 'Mage'].map((
                            String category,
                          ) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setStateDialog(() {
                              _selectedHeroCategory = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _formSiapTanding,
                          activeColor: const Color(0xFF3AC394),
                          fillColor: WidgetStateProperty.resolveWith<Color>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF3AC394);
                            }
                            return Colors.white54;
                          }),
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              _formSiapTanding = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "Saya dan lawan menyatakan siap tanding",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AC394),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (_selectedHeroCategory == null || !_formSiapTanding) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Pilih kategori hero & centang siap tanding dulu kawan!",
                          ),
                        ),
                      );
                      return;
                    }

                    // 1. Simpan data ke Database MySQL melalui PHP
                    await _simpanKesepakatanKeServer();

                    // 2. Kirim otomatis hasil kesepakatan ke chat agar terekam oleh lawan
                    _chatController.text =
                        "[SISTEM KESEPAKATAN] Kategori Hero: $_selectedHeroCategory | Status: SEPAKAT SIAP TANDING!";
                    await _kirimPesan();

                    if (context.mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kesepakatan berhasil disimpan kawan!"),
                        ),
                      );
                      Navigator.pop(
                        context,
                        true,
                      ); // Tutup dialog dan kembalikan true
                    }
                  },
                  child: const Text(
                    "Simpan & Konfirmasi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk memunculkan Dialog Penjelasan Awal / Briefing Kawan
  void _tampilkanDialogPenjelasanAwal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Membuat bottom sheet bisa menyesuaikan tinggi & discroll jika kontennya panjang
      backgroundColor: Colors
          .transparent, // Transparan agar border radius container terlihat rapi
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D4661), // Warna latar belakang sesuai desain Anda
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 15,
            // Menghindari tertutup keyboard atau bagian bawah layar (SafeArea)
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            child: MainAxisSize.min == MainAxisSize.min
                ? Wrap(
                    children: [
                      // Garis indikator kecil di atas (opsional, ciri khas bottom sheet modern)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Judul Bottom Sheet
                      const Text(
                        "Panduan & Tata Cara Tanding BY ONE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Konten Teks Panduan (Bisa discroll)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height *
                              0.6, // Maksimal 60% tinggi layar
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Sebelum melakukan tanding wajib melakukan kesepakatan antara kedua peserta, berikut kesepakatan yang harus dilakukan :",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "📢 Penentuan Posisi (Home / Away)\n"
                                "• Lakukan kesepakatan Posisi!\n"
                                "• Peserta yang disepakati sebagai HOME wajib membuat Master Room di MLBB, lalu invite lawan, melakukan pengaturan agar dapat bermain BY ONE atau 1v1 dan melakukan recording pertandingan.\n"
                                "• Peserta AWAY wajib bersiap di ruang tunggu dan masuk sesuai undangan.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "📢 Aturan Main di dalam In-Game\n"
                                "• Durasi : Maksimal 5 Menit 25 detik .\n"
                                "• Pemenang : Dihitung berdasarkan perolehan Kill Terbanyak saat waktu habis\n"
                                "• Larangan Keras : Dilarang menyerang, mencuri, atau mengganggu *buff* (baik buff sendiri maupun buff tengah/lawan), dilarang keras menggunakan cheat.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "📢 Konfirmasi Kesepakatan\n"
                                "• Setelah melakukan kesepakatan pemain yang disepakati sebagai HOME harus melakukan Konfirmasi Kesepakatan pada halaman ini dengan klik tombol Konfirmasi Kesepakatan\n\n",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tombol Aksi (Mengerti) di bagian bawah
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Mengerti",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    print('==============================>');
    print("ISI MATCH DATA: ${widget.matchData}");

    print("ISI MATCH DATA: ${widget.opponentGoogleId}");
    print('<==============================');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tampilkanDialogPenjelasanAwal();
    });
    _selectedOpponentId = widget.opponentGoogleId.isNotEmpty
        ? widget.opponentGoogleId
        : null;
    _ambilRiwayatChat();

    // Polling setiap 3 detik kawan
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _ambilRiwayatChat();
    });
    if (widget.currentGoogleId == widget.matchData['player1']?['google_id']) {
    } else {}

    // Cek apakah key-nya benar-benar ada di dalam matchData
    if (widget.currentGoogleId == widget.matchData['player1']?['google_id']) {
    } else {}
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 1. FUNGSI GET RIWAYAT CHAT KAWAN
  Future<void> _ambilRiwayatChat() async {
    final String targetOpponent =
        _selectedOpponentId ?? widget.opponentGoogleId;
    if (targetOpponent.isEmpty) return;

    // 🔥 Menyertakan parameter round dan match_number ke URL API kawan
    final String url =
        "https://donorta.tech/apimabarscore/get_arena_chats.php?arena_id=${widget.arenaId}&round=${widget.round}&match_number=${widget.matchNumber}&user_id=${widget.currentGoogleId}&opponent_id=$targetOpponent";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' &&
            data['data'] != null &&
            data['data'] is List) {
          if (mounted) {
            setState(() {
              _chatMessages = data['data'];
              _isLoading = false;
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _lompatKeBawah());
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil chat kawan: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. FUNGSI POST KIRIM PESAN MULTIPART (FIXED ERROR PARAMS) KAWAN
  Future<void> _kirimPesan({File? gambarFile}) async {
    final String targetOpponent =
        _selectedOpponentId ?? widget.opponentGoogleId;

    // Validasi agar tidak mengirim data kosong kawan
    if (gambarFile == null && _chatController.text.trim().isEmpty) return;
    if (targetOpponent.isEmpty) return;

    final String url = "https://donorta.tech/apimabarscore/send_arena_chat.php";
    final String pesanTeks = _chatController.text.trim();

    // Kosongkan langsung kolom input teks kawan
    _chatController.clear();

    try {
      // Mengubah request menjadi Multipart agar mendukung unggah gambar fisik kawan
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['arena_id'] = widget.arenaId;
      request.fields['round'] = widget.round
          .toString(); // 🔥 Kirim data round aktif
      request.fields['match_number'] = widget.matchNumber
          .toString(); // 🔥 Kirim data nomor match aktif
      request.fields['sender_google_id'] = widget.currentGoogleId;
      request.fields['receiver_google_id'] = targetOpponent;
      request.fields['message'] = pesanTeks;

      // Jika parameter gambarFile disisipkan oleh fungsi picker gambar
      if (gambarFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', gambarFile.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _ambilRiwayatChat(); // Ambil data chat teranyar kawan
        debugPrint("Response data dari PHP kawan: ${response.body}");
      }
    } catch (e) {
      debugPrint("Gagal mengirim chat kawan: $e");
    }
  }

  void _lompatKeBawah() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pilihGambarDanKirim() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      // Sekarang parameter ini sudah aman didefinisikan kawan!
      _kirimPesan(gambarFile: File(pickedFile.path));
    }
  }

  // Fungsi untuk mengecek apakah kedua peserta sudah saling balas chat kawan
  bool _sudahSalingBalasChat() {
    bool sayaPernahChat = false;
    bool lawanPernahChat = false;

    final String targetOpponent =
        _selectedOpponentId ?? widget.opponentGoogleId;

    for (var chat in _chatMessages) {
      final String senderId = (chat['sender_google_id'] ?? '').toString();
      final dynamic isMeRaw = chat['is_me'];

      bool isMe = false;
      if (isMeRaw != null) {
        isMe =
            (isMeRaw == true ||
            isMeRaw == 1 ||
            isMeRaw.toString() == "true" ||
            isMeRaw.toString() == "1");
      } else if (senderId.isNotEmpty) {
        isMe = (senderId == widget.currentGoogleId);
      }

      if (isMe) {
        sayaPernahChat = true;
      } else if (senderId == targetOpponent) {
        lawanPernahChat = true;
      }

      // Jika keduanya sudah pernah mengirim pesan, langsung return true kawan!
      if (sayaPernahChat && lawanPernahChat) {
        return true;
      }
    }

    return false;
  }

  Future<void> _launchWhatsAppone() async {
    final String phoneNumber = "6283180103379";
    final String message = "Halo Admin, saya butuh bantuan terkait MabarScore.";

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // Tampilkan error jika WhatsApp tidak terinstall atau gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal membuka WhatsApp. Pastikan WhatsApp sudah terinstall.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C4A60), Color(0xFF145347), Color(0xFF249B76)],
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/bgchat.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Chat arena ${widget.arenaId}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              Navigator.pop(
                context,
                true,
              ); // Kembalikan true agar halaman sebelumnya tahu ada update chat
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.emoji_events, color: Colors.amber[700]),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // DROPDOWN
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Visibility(
                visible: false, // Sembunyikan dropdown lawan kawan
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOpponentId,
                    hint: const Text(
                      "Pilih id lawan",
                      style: TextStyle(color: Colors.black54),
                    ),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.blue,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: widget.opponentGoogleId,
                        child: Text(
                          widget.opponentGoogleId.isNotEmpty
                              ? "(${widget.opponentGoogleId})"
                              : "Tidak ada lawan",
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedOpponentId = value;
                        _isLoading = true;
                      });
                      _ambilRiwayatChat();
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics:
                    const BouncingScrollPhysics(), // Efek pantul saat mentok (opsional)
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Tombol Info
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(199, 20, 44, 43),
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Bentuk pill membulat
                        border: Border.all(
                          color: const Color(0xFF313D48),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _tampilkanDialogPenjelasanAwal();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Info',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // Jarak antar tombol
                    // 2. Tombol Lapor Admin
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(199, 20, 44, 43),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF313D48),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _launchWhatsAppone();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.support_agent_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Lapor admin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // Jarak antar tombol
                    // 3. Tombol Konfirmasi Kesepakatan
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(199, 20, 44, 43),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF313D48),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // Validasi: Cek apakah sudah saling balas chat kawan
                            if (!_sudahSalingBalasChat()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Minimal harus ada saling balas chat terlebih dahulu dengan lawan sebelum membuat kesepakatan kawan!",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            // Jika sudah saling balas, izinkan buka dialog konfirmasi
                            _tampilkanDialogKesepakatanDanKonfirmasi();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.published_with_changes_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Konfir Kesepakatan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
            const SizedBox(height: 16),
            // AREA BUBBLE CHAT
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _chatMessages.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada obrolan kawan.\nKirim pesan duluan yuk!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final chat = _chatMessages[index];

                        final String senderId = (chat['sender_google_id'] ?? '')
                            .toString();
                        final dynamic isMeRaw = chat['is_me'];

                        bool isMe = false;
                        if (isMeRaw != null) {
                          isMe =
                              (isMeRaw == true ||
                              isMeRaw == 1 ||
                              isMeRaw.toString() == "true" ||
                              isMeRaw.toString() == "1");
                        } else if (senderId.isNotEmpty) {
                          isMe = (senderId == widget.currentGoogleId);
                        }

                        final String isiPesan = chat['message'] ?? '';
                        // LOGIKA BARU KAWAN: Cek jika data teks string diawali prefix penanda nama file gambar
                        final bool adalahPesanGambar = isiPesan.startsWith(
                          "IMG_",
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // AVATAR KIRI (Lawan)
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blue,
                                  backgroundImage:
                                      (chat['avatar_url'] != null &&
                                          chat['avatar_url']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(
                                          chat['avatar_url'].toString(),
                                        )
                                      : null,
                                  child:
                                      (chat['avatar_url'] == null ||
                                          chat['avatar_url'].toString().isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Bubble Chat Box (Bisa menampung Teks biasa maupun Gambar kawan)
                              Flexible(
                                child: Container(
                                  padding: adalahPesanGambar
                                      ? const EdgeInsets.all(
                                          5,
                                        ) // Padding minimalis bingkai foto kawan
                                      : const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color.fromARGB(
                                            111,
                                            232,
                                            234,
                                            246,
                                          )
                                        : const Color.fromARGB(
                                            111,
                                            232,
                                            234,
                                            246,
                                          ),
                                    border: isMe
                                        ? Border.all(color: Colors.white24)
                                        : Border.all(color: Colors.greenAccent),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(
                                        isMe ? 20 : 0,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 0 : 20,
                                      ),
                                    ),
                                  ),
                                  // Cari potongan kode ini di bagian list builder kawan:
                                  child: adalahPesanGambar
                                      ? GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailGambarView(
                                                      urlGambar:
                                                          "$_imageBaseUrl$isiPesan",
                                                    ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            child: Image.network(
                                              "$_imageBaseUrl$isiPesan",
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              // ... errorBuilder milikmu kawan
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const SizedBox(
                                                      width: 180,
                                                      height: 100,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 35,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        )
                                      : GestureDetector(
                                          // 👇 Aksi ketika teks pesan ditekan lama kawan
                                          onLongPress: () async {
                                            if (isiPesan.isNotEmpty) {
                                              // 1. Perintah untuk menyalin teks ke clipboard HP kawan
                                              await Clipboard.setData(
                                                ClipboardData(text: isiPesan),
                                              );

                                              // 2. Munculkan notifikasi snackbar di bawah layar kawan
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    "Teks chat berhasil disalin kawan!",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.blueGrey[800],
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  behavior: SnackBarBehavior
                                                      .floating, // Membuat snackbar melayang rapi
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            isiPesan,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                ),
                              ),

                              // AVATAR KANAN (Kita)
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFFFC107),
                                  backgroundImage:
                                      (chat['avatar_url'] != null &&
                                          chat['avatar_url']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(
                                          chat['avatar_url'].toString(),
                                        )
                                      : null,
                                  child:
                                      (chat['avatar_url'] == null ||
                                          chat['avatar_url'].toString().isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // INPUT BAR DI BAGIAN BAWAH KAWAN (Gaya WhatsApp Kontras)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: Colors.transparent,
              child: Row(
                children: [
                  // 1. TOMBOL AMBIL GAMBAR GALERI
                  GestureDetector(
                    onTap: _pilihGambarDanKirim,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.navBarIconUnselected,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 2. KOLOM KETIK TEKS
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ketik pesan kesepakatan roo...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.white24,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. TOMBOL KIRIM PESAN TEKS
                  GestureDetector(
                    onTap: () => _kirimPesan(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Color(0xFFFFC107),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
