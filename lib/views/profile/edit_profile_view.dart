import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mabarscore/core/models/player_model.dart';

// Gantilah import model Player sesuai lokasi file di project-mu kawan
// import 'package:mabarscore/models/player.dart';

class EditProfileView extends StatefulWidget {
  final dynamic currentPlayer; // Menerima data user saat ini kawan

  const EditProfileView({Key? key, required this.currentPlayer})
    : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk form input kawan
  late TextEditingController _nicknameController;
  late TextEditingController _mlbbIdController;
  late TextEditingController _originController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dari data user yang ada kawan
    _nicknameController = TextEditingController(
      text: widget.currentPlayer.nickname ?? '',
    );
    _mlbbIdController = TextEditingController(
      text:
          (widget.currentPlayer.mlbbId == 'null' ||
              widget.currentPlayer.mlbbId == '-')
          ? ''
          : widget.currentPlayer.mlbbId ?? '',
    );
    _originController = TextEditingController(
      text: widget.currentPlayer.origin ?? 'Indonesia - Makassar',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _mlbbIdController.dispose();
    _originController.dispose();
    super.dispose();
  }

  // 🔥 FUNGSI TEMBAK API UPDATE KE BACKEND VPS KAWAN
  // 🔥 FUNGSI TEMBAK API UPDATE KE BACKEND VPS KAWAN
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Sesuaikan dengan URL base API mabarscore milikmu kawan
    final url = Uri.parse(
      "https://donorta.tech/apimabarscore/update_profile_dua.php",
    );

    try {
      final response = await http
          .post(
            url,
            body: {
              "google_id": widget.currentPlayer.googleId.toString(),
              "nickname": _nicknameController.text.trim(),
              "mlbb_id": _mlbbIdController.text.trim(),
              "origin": _originController.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.body);

        if (res['status'] == 'success') {
          // 🔥 SINKRONISASI TOTAL SESUAI CONSTRUCTOR PLAYER_MODEL.DART KAWAN
          // Kita buat objek Player baru murni dengan mempertahankan data lama,
          // kecuali data hasil ketikan form input yang baru saja diupdate kawan.
          final updatedUser = Player(
            id: widget.currentPlayer.id,
            googleId: widget.currentPlayer.googleId,
            email: widget.currentPlayer.email,
            avatarUrl: widget.currentPlayer.avatarUrl,
            coinsBalance: widget.currentPlayer.coinsBalance,

            kontak: widget.currentPlayer.kontak,
            fcmToken: widget.currentPlayer.fcmToken,
            status: widget.currentPlayer.status,
            // 3 Akun Gaji dipertahankan nilainya kawan agar tidak hilang
            paymentMethod: widget.currentPlayer.paymentMethod,
            paymentNumber: widget.currentPlayer.paymentNumber,
            paymentName: widget.currentPlayer.paymentName,

            // Masukkan data baru hasil ketikan dari form kawan:
            nickname: _nicknameController.text.trim(),
            mlbbId: _mlbbIdController.text.trim(),
            origin: _originController.text.trim(),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profilmu berhasil diperbarui kawan!"),
                backgroundColor: Colors.green,
              ),
            );
            // 🔥 LEMPAR BALIK KE UPLOAD BUKTI KAWAN
            Navigator.pop(context, updatedUser);
          }
        } else {
          _showErrorDialog(res['message'] ?? "Gagal memperbarui profil kawan.");
        }
      } else {
        _showErrorDialog(
          "Respon server bermasalah (Code: ${response.statusCode}) kawan.",
        );
      }
    } catch (e) {
      _showErrorDialog("Terjadi kesalahan jaringan: $e kawan.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF163E56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Eror Kawan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tutup",
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1F2E35,
      ), // Tema gelap khas mabarscore kawan
      appBar: AppBar(
        title: const Text(
          "Edit Profil Mabar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF163E56),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () =>
              Navigator.pop(context, null), // Kirim null jika batal kawan
        ),
      ),
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // Tutup keyboard otomatis kawan
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Google Akun (Read-only kawan)
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orangeAccent,
                        backgroundImage:
                            widget.currentPlayer.avatarUrl != null &&
                                widget.currentPlayer.avatarUrl!.isNotEmpty
                            ? NetworkImage(widget.currentPlayer.avatarUrl!)
                            : null,
                        child:
                            widget.currentPlayer.avatarUrl == null ||
                                widget.currentPlayer.avatarUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.currentPlayer.email ?? '',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Input Nickname Game kawan
                const Text(
                  "Nickname Mabarscore",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    Icons.sports_esports_rounded,
                    "Masukkan Nickname",
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Nickname tidak boleh kosong kawan!"
                      : null,
                ),
                const SizedBox(height: 20),

                // 🔥 FIELD UTAMA: INPUT ID MOBILE LEGENDS KAWAN
                const Text(
                  "ID Mobile Legends (MLBB)",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mlbbIdController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      TextInputType.number, // Memaksa keyboard angka kawan
                  decoration: _buildInputDecoration(
                    Icons.fingerprint_rounded,
                    "Contoh: 123456789 (4321)",
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "ID MLBB wajib diisi untuk validasi pertandingan kawan!";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input Asal/Origin daerah kawan
                const Text(
                  "Asal Daerah / Kota",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _originController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    Icons.location_on_rounded,
                    "Contoh: Indonesia - Makassar",
                  ),
                ),
                const SizedBox(height: 40),

                // Tombol Simpan Keren kawan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Simpan Perubahan Profil",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF163E56),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
      ),
    );
  }
}
