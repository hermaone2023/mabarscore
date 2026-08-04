import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/models/player_model.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:mabarscore/views/profile/edit_profile_view.dart';

class UploadReportView extends StatefulWidget {
  final Player currentPlayer;
  final String
  matchId; // 🔥 Diambil langsung dari kolom id tabel fivehero_matches kawan!

  const UploadReportView({
    Key? key,
    required this.currentPlayer,
    required this.matchId,
  }) : super(key: key);

  @override
  State<UploadReportView> createState() => _UploadReportViewState();
}

class _UploadReportViewState extends State<UploadReportView> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late Player _user;
  @override
  void initState() {
    super.initState();
    // 2. Inisialisasi variabel lokal dari widget atas kawan
    _user = widget.currentPlayer;
  }

  // State untuk menyimpan pilihan hasil tanding kawan
  String? _selectedStatus; // 'Menang' atau 'Kalah'

  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitReport() async {
    // ==========================================
    // 🔥 VALIDASI SAKTI ID MLBB SEBELUM KIRIM KAWAN 🔥
    // ==========================================
    // Menggunakan _user (variabel lokal) kawan, bukan widget.currentPlayer
    if (_user.mlbbId == null ||
        _user.mlbbId!.isEmpty ||
        _user.mlbbId == "null" ||
        _user.mlbbId == "-") {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF163E56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text(
                    "ID MLBB Belum Diatur!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Gagal mengirim laporan kawan! Kamu harus mengisi ID Mobile Legends kamu terlebih dahulu di profil agar sistem bisa melakukan validasi silang.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Nanti Saja",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Tutup dialog peringatan

                    // Arahkan ke halaman edit profile kawan
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileView(
                          currentPlayer: _user, // Memakai data user lokal kawan
                        ),
                      ),
                    );

                    // AMAN! Sekarang variabel lokal bisa diubah di dalam setState kawan!
                    if (updatedUser != null && mounted) {
                      setState(() {
                        _user =
                            updatedUser; // Mengupdate variabel lokal pembawa ID MLBB baru
                      });
                    }
                  },
                  child: const Text(
                    "Atur Sekarang",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
      return; // Stop eksekusi kawan
    }
    // ==========================================

    if (!_formKey.currentState!.validate()) return;

    // 1. Validasi pilihan status Menang/Kalah kawan
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kawan, pilih status hasil tandingmu (Menang/Kalah)!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Validasi file screenshot
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kawan, bukti screenshot wajib dilampirkan!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    // 🔥 Menggunakan googleId dari variabel _user lokal kawan
    final res = await _apiService.uploadMatchReport(
      matchId: widget.matchId,
      googleId:
          _user.googleId, // Menggunakan variabel lokal yang fleksibel kawan
      statusClaim: _selectedStatus!,
      screenshotFile: _selectedImage!,
    );

    setState(() => _isUploading = false);

    if (res != null) {
      if (res['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['detail'] ?? "Laporan berhasil terkirim kawan!",
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          final String errMsg = res['message'] ?? "Terjadi kesalahan";
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF163E56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    "Gagal Mengirim",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                errMsg,
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan jaringan atau server kawan."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload Bukti Tanding",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF163E56),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            // 🚀 Lempar user lokal saat ini kawan, agar profil utama ikut ter-update
            Navigator.pop(context, _user);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Setor Laporan Pertandingan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Sistem mendeteksi kamu baru saja menyelesaikan pertandingan dengan Match ID #${widget.matchId}. Silakan laporkan hasilnya secara jujur kawan.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔥 KARTU INFORMASI DIGITAL (Bukan Input Lapangan Lagi Kawan!)
                  // 🔥 KARTU INFORMASI DIGITAL (Sudah Otomatis Penuh Kawan!)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF163E56).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        // 1. ID Pertandingan dari tabel fivehero_matches
                        _buildInfoRow(
                          Icons.tag,
                          "ID Pertandingan",
                          widget.matchId,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.white12, height: 1),
                        ),

                        // 2. Google ID otomatis dari Session Login Player (Baru ditambahkan ke UI)
                        _buildInfoRow(
                          Icons
                              .g_mobiledata_rounded, // Icon representasi Google kawan
                          "Google ID",
                          widget.currentPlayer.googleId,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Colors.white12, height: 1),
                        ),

                        // 3. ID Mobile Legends otomatis dari tabel Player
                        // 🔥 KODE BARU (Sudah otomatis sinkron & reaktif kawan!)
                        _buildInfoRow(
                          Icons.account_circle_outlined,
                          "ID Mobile Legends",
                          (_user.mlbbId == null ||
                                  _user.mlbbId!.isEmpty ||
                                  _user.mlbbId == "null" ||
                                  _user.mlbbId == "-")
                              ? "Belum Diatur"
                              : _user.mlbbId!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 1. PILIHAN STATUS TANDING (MENANG / KALAH)
                  const Text(
                    "Hasil Pertandingan Kamu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          statusName: "Menang",
                          icon: Icons.emoji_events_rounded,
                          activeColor: const Color(0xFF4FA98A),
                          isSelected: _selectedStatus == "Menang",
                          onTap: () =>
                              setState(() => _selectedStatus = "Menang"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          statusName: "Kalah",
                          icon: Icons.sentiment_very_dissatisfied_rounded,
                          activeColor: Colors.redAccent,
                          isSelected: _selectedStatus == "Kalah",
                          onTap: () =>
                              setState(() => _selectedStatus = "Kalah"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 2. Area Lampiran Bukti Screenshot
                  const Text(
                    "Lampiran Bukti Screenshot",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _isUploading ? null : _pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF163E56).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Color(0xFF4FA98A),
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Ketuk untuk pilih Gambar Screenshot",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "(Format: JPG, JPEG, PNG)",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // 3. Tombol Kirim Laporan kawan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FA98A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isUploading ? null : _submitReport,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "KIRIM LAPORAN SEKARANG",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
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

  // Widget Baris Info untuk menggantikan form input ketik manual kawan
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4FA98A), size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // _buildStatusCard
  Widget _buildStatusCard({
    required String statusName,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : const Color(0xFF163E56).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              statusName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
