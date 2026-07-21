import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/views/fivehero/detail_gambar_view.dart';

class FiveheroChatView extends StatefulWidget {
  final String arenaId;
  final String currentGoogleId; // ID User yang sedang login kawan
  final String opponentGoogleId; // ID Lawan yang dipilih dari dropdown kawan
  final Map<String, dynamic> matchData;

  const FiveheroChatView({
    Key? key,
    required this.arenaId,
    required this.currentGoogleId,
    required this.opponentGoogleId,
    required this.matchData,
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
  // Default false
  bool _isUserReady = false; // Default false

  String? _selectedOpponentId;

  // Sesuaikan domain URL direktori gambar di server kawan
  final String _imageBaseUrl =
      "https://donorta.tech/apimabarscore/uploads/chats/";

  @override
  void initState() {
    super.initState();
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
      _isUserReady = widget.matchData['player_1_id_siap'].toString() == "1";
    } else {
      _isUserReady = widget.matchData['player_2_id_siap'].toString() == "1";
    }
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

    final String url =
        "https://donorta.tech/apimabarscore/get_arena_chats.php?arena_id=${widget.arenaId}&user_id=${widget.currentGoogleId}&opponent_id=$targetOpponent";

    try {
      final response = await http.get(Uri.parse(url));

      // debugPrint("Isi dari GET_ARENA_CHATS kawan: ${response.body}");

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

  Future<void> _updateStatusSiapKeDatabase() async {
    try {
      final response = await http.post(
        Uri.parse("https://donorta.tech/apimabarscore/update_match_status.php"),
        body: {
          'match_id': widget.arenaId.toString(),
          'google_id': widget.currentGoogleId,
        },
      );

      if (response.statusCode == 200) {
        print("Status berhasil diupdate!");
      }
    } catch (e) {
      print("Error update: $e");
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
              // 1. Cek apakah user sudah siap sebelumnya
              if (_isUserReady) {
                // Jika sudah siap, langsung keluar tanpa dialog
                Navigator.pop(context);
              } else {
                // 2. Jika belum siap, tampilkan dialog
                bool? isAgreed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: const Color(0xFF0D4661),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF3AC394),
                            size: 50,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Konfirmasi Kesepakatan",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Apakah kamu telah melakukan kesepakatan aturan tanding dengan lawanmu?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    false,
                                  ), // Dialog tutup dengan nilai false
                                  child: const Text(
                                    "Belum",
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3AC394),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(
                                    context,
                                    true,
                                  ), // Dialog tutup dengan nilai true
                                  child: const Text(
                                    "OK, SIAP",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // 3. Proses hasil dialog
                if (isAgreed == true) {
                  // Jika user klik "OK, SIAP"
                  await _updateStatusSiapKeDatabase();
                  if (context.mounted) {
                    setState(() => _isUserReady = true);
                    Navigator.pop(context); // Keluar halaman
                  }
                } else {
                  // Jika user klik "Belum" atau menutup dialog (isAgreed == false atau null)
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                    ); // 🔥 TAMBAHKAN INI agar halaman ikut keluar
                  }
                }
              }
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
            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: 24.0,
            //     vertical: 12.0,
            //   ),
            //   child: Text(
            //     "Lakukan kesepakatan untuk membuat arena tanding 1 vs 1 bersama lawanmu kemudian mulailah tanding",
            //     style: const TextStyle(
            //       color: Colors.white,
            //       fontSize: 15,
            //       height: 1.3,
            //     ),
            //     textAlign: TextAlign.center,
            //   ),
            // ),

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
