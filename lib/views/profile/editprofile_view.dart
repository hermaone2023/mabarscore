import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileView extends StatefulWidget {
  final String googleId;
  final String currentNickname;
  final String currentOrigin;
  final String currentMlbbId;
  final String currentKontak;
  final String currentAvatarUrl;

  const EditProfileView({
    super.key,
    required this.googleId,
    required this.currentNickname,
    required this.currentOrigin,
    required this.currentMlbbId,
    required this.currentKontak,
    required this.currentAvatarUrl,
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _originController;
  late TextEditingController _mlbbIdController;
  late TextEditingController _kontakController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentNickname);
    _originController = TextEditingController(text: widget.currentOrigin);
    _mlbbIdController = TextEditingController(text: widget.currentMlbbId);
    _kontakController = TextEditingController(text: widget.currentKontak);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _mlbbIdController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Player bisa klik di luar untuk membatalkan
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: const Color(
            0xFF0D4661,
          ), // Mengikuti base dark blue UI kamu kawan
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(
                  0xFF3AC394,
                ).withValues(alpha: 0.3), // Border tipis hijau transparan
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. IKON PERINGATAN MODEREN
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135A64).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .power_settings_new_rounded, // Ikon power/logout yang modern
                    color: Color(0xFF3AC394), // Aksen hijau terang
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. JUDUL DIALOG
                const Text(
                  "Konfirmasi Keluar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. DESKRIPSI Teks
                Text(
                  "Apakah kamu yakin ingin keluar dari akun Mabar Score kawan?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // 4. TOMBOL AKSI (Batal & Keluar) kawan
                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Keluar (Aksen Tegas)
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Tutup dialog dulu kawan
                            _handleLogout(); // Jalankan fungsi hapus session
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFD9534F,
                            ), // Merah soft untuk indikasi aksi destruktif/keluar
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Keluar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
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

  File? _imageFile; // Variabel untuk menyimpan file gambar yang dipilih
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk memilih gambar dari Galeri
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality:
            70, // Kompres kualitas ke 70% agar ukuran file tidak terlalu besar
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  // MENGUBAH FUNGSI UPDATE PROFILE MENJADI MULTIPART
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String url =
        "https://donorta.tech/apimabarscore/new_update_profile.php";

    try {
      // Menggunakan MultipartRequest karena kita akan mengirim file
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Masukkan data teks (Form Fields)
      request.fields['google_id'] = widget.googleId;
      request.fields['nickname'] = _nameController.text.trim();
      request.fields['origin'] = _originController.text.trim();
      request.fields['mlbb_id'] = _mlbbIdController.text.trim();
      request.fields['kontak'] = _kontakController.text.trim();
      request.fields['current_avatar_url'] =
          widget.currentAvatarUrl; // Kirim URL lama sebagai fallback

      // Masukkan file gambar jika player memilih foto baru
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar_file', // Nama key yang akan dibaca di PHP ($_FILES['avatar_file'])
            _imageFile!.path,
          ),
        );
      }

      // Kirim request ke server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final prefs = await SharedPreferences.getInstance();
          String? userSession = prefs.getString('user_session');

          if (userSession != null) {
            Map<String, dynamic> userMap = jsonDecode(userSession);

            // Update data teks (Semuanya disimpan sebagai String kawan!)
            userMap['nickname'] = _nameController.text.trim();
            userMap['origin'] = _originController.text.trim();
            userMap['mlbb_id'] = _mlbbIdController.text
                .trim(); // Simpan sebagai String
            userMap['kontak'] = _kontakController.text
                .trim(); // 🔥 SOLUSI UTAMA: Tetap simpan sebagai String agar sinkron dengan varchar(50) database!

            // Update URL Avatar Baru dari server
            if (data['new_avatar_url'] != null) {
              userMap['avatar_url'] = data['new_avatar_url'];
            }

            // Tulis ulang session lokal yang baru kawan
            await prefs.setString('user_session', jsonEncode(userMap));
          }

          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        throw Exception("Gagal terhubung ke server (${response.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradasi Latar Belakang Sesuai Mockup UI
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Edit Profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Balancer space untuk arrow back
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 3,
                          bottom: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xff090900).withValues(alpha: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            'Log Out',
                            style: TextStyle(color: Colors.lightGreenAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FORM FIELDS (SCROLLABLE)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // FOTO PROFIL & CIRCLING ICON CAMERA
                        // FOTO PROFIL & CIRCLING ICON CAMERA
                        Center(
                          child: GestureDetector(
                            onTap:
                                _pickImage, // Klik area foto atau ikon untuk ganti gambar
                            child: Stack(
                              children: [
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade700,
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      // JIKA ada gambar baru yang dipilih, tampilkan FileImage. Jika tidak, pakai NetworkImage dari URL lama.
                                      image: _imageFile != null
                                          ? FileImage(_imageFile!)
                                                as ImageProvider
                                          : NetworkImage(
                                              widget.currentAvatarUrl,
                                            ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5CD8A5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Color(0xFF0D4661),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // INPUT NAMA
                        _buildLabel("Nama"),
                        _buildTextField(_nameController, "Masukkan nama baru"),
                        const SizedBox(height: 18),

                        // INPUT ASAL - ORIGIN
                        _buildLabel("Asal - Origin"),
                        _buildTextField(
                          _originController,
                          "Indonesia - Makassar",
                        ),
                        const SizedBox(height: 18),

                        // INPUT ID MOBILE LEGEND
                        _buildLabel("ID Mobile Legend"),
                        _buildTextField(
                          _mlbbIdController,
                          "1234567890",
                          isNumeric: true,
                        ),
                        const SizedBox(height: 18),

                        // INPUT KONTAK (NO WHATSAPP)
                        _buildLabel("Kontak(No WhatsApp)"),
                        _buildTextField(
                          _kontakController,
                          "094305353534",
                          isNumeric: true,
                        ),
                        const SizedBox(height: 40),

                        // TOMBOL SIMPAN
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF135A64,
                              ), // Teal pekat tombol simpan
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "SIMPAN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(
          0xFF165968,
        ).withValues(alpha: 0.8), // Warna kotak input gelap transparan
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.amberAccent),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Bagian ini tidak boleh kosong kawan";
        }
        return null;
      },
    );
  }
}
