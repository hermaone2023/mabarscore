import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mabarscore/views/fivehero/fivehero_detail_view.dart';
import 'package:mabarscore/views/profile/dokumentasi.dart';
import 'package:mabarscore/views/profile/editprofile_view.dart';
import 'package:mabarscore/views/profile/feedback_view.dart';
import 'package:mabarscore/views/profile/top_up_view.dart';
import 'package:mabarscore/views/profile/upload_report_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/models/player_model.dart';
import 'package:mabarscore/core/services/api_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isLoading = true;
  int _currentCoinBalance = 0;
  Player? _currentPlayer;
  bool _isLoadingCoins = true;
  Map<String, dynamic>? _participationData;
  final ApiService _apiService = ApiService();

  Future<void> _submitReferral(String code) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/process_referral.php"),
        // 🔥 TAMBAHKAN HEADERS DI SINI KAWAN!
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": _currentPlayer!.id,
          "referral_code":
              code, // Menggunakan parameter fungsi agar lebih fleksibel
        }),
      );

      // Cek apakah request berhasil (status code 200)
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == true) {
          // Berhasil: Tampilkan pesan sukses
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
          // Tips: Kamu bisa panggil fungsi update saldo koin di sini jika ada
        } else {
          // Gagal (tapi terhubung): Tampilkan pesan error dari PHP
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
        }
      } else {
        // Error Server (misal 500 atau 404)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server sedang sibuk, coba lagi nanti kawan!"),
          ),
        );
      }
    } catch (e) {
      // Error Koneksi
      print("Error saat submit referral: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server kawan!")),
      );
    }
  }

  void _showReferralInput() {
    TextEditingController _refController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            const Text(
              "Kode Referral",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Bantu temanmu untuk mendapatkan 5 koin dengan memasukkan kode referalnya",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _refController,
              textCapitalization:
                  TextCapitalization.characters, // Otomatis kapital
              decoration: InputDecoration(
                hintText: "Masukkan kode...",
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.code),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              if (_refController.text.trim().isNotEmpty) {
                _submitReferral(_refController.text.trim().toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Kirim",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mengecek apakah user pernah topup di database
  Future<bool> _checkHasTopup() async {
    final response = await http.post(
      Uri.parse(
        "${ApiService.baseUrl}/check_topup.php",
      ), // Masukkan URL lengkapnya di sini
      body: {"google_id": _currentPlayer!.googleId},
    );
    print(
      "Response API: ${response.body}",
    ); // 🔥 Lihat di Log Cat/Debug Console
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      bool isTopup = data['has_topup'];
      print("Hasil Boolean: $isTopup");
      return isTopup;
    }
    return false;
  }

  // Fungsi masking kode (ABC123 -> ABC***)
  String _maskReferralCode(String code) {
    if (code.length <= 3) return code;
    return "${code.substring(0, 3)}***";
  }

  // Dialog Peringatan
  void _showTopupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            const Text(
              "oppps..!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Lakukan minimal 1 kali topup koin untuk dapat membagikan kode referalmu !",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nanti Saja"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TopUpView()),
              );

              // Setelah kembali, refresh saldonya
              _refreshCoins();
            },

            child: const Text("Topup Sekarang"),
          ),
        ],
      ),
    );
  }

  Future<String?> _fetchReferralCode() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/get_referral.php?google_id=${_currentPlayer!.googleId}",
        ),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == true) {
          return data['referral_code'];
        }
      }
    } catch (e) {
      print("Gagal ambil referral: $e");
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Pastikan profile dimuat dulu
    await _loadPlayerProfile();
    // Setelah profil ada, baru tarik saldo
    _refreshCoins();
    _getdataParticipation();
  }

  Future<void> _getdataParticipation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? gid = prefs.getString('google_id');

    if (gid != null) {
      // Panggil service kita
      final result = await _apiService.getPlayerParticipation(gid);

      if (result != null && result['status'] == 'success') {
        setState(() {
          _participationData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshCoins() async {
    // 1. Cek apakah currentPlayer sudah ada
    if (_currentPlayer == null || _currentPlayer!.googleId.isEmpty) {
      debugPrint("Player belum siap kawan, skip refresh koin.");
      return;
    }

    // 2. Gunakan try-finally agar loading pasti berhenti meski error
    setState(() => _isLoadingCoins = true);
    try {
      final balance = await _apiService.getCoinsBalance(
        googleId: _currentPlayer!.googleId,
      );

      if (mounted) {
        setState(() {
          _currentCoinBalance = balance;
        });
      }
    } catch (e) {
      debugPrint("Gagal load koin: $e");
      // Opsional: set balance ke 0 atau tampilkan snackbar
    } finally {
      if (mounted) {
        setState(() => _isLoadingCoins = false);
      }
    }
  }

  Future<void> _loadPlayerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userSession = prefs.getString('user_session');

      if (userSession != null) {
        setState(() {
          _currentPlayer = Player.fromJson(jsonDecode(userSession));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Gagal memuat profil lokal kawan: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<String> _fetchLatestAvatar(String googleId) async {
    // 🔥 SOLUSI: Menggunakan string interpolation ($googleId) dari parameter fungsi kawan
    final String url =
        "https://donorta.tech/apimabarscore/get_avatar.php?google_id=$googleId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['avatar_url'] != null) {
          return data['avatar_url'].toString();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetch avatar backend: $e");
    }
    // Jika gagal, kembalikan string kosong kawan
    return "";
  }

  showEditProfileDialog() {
    final nicknameController = TextEditingController(
      text: _currentPlayer!.nickname,
    );
    final mlbbIdController = TextEditingController(
      text: _currentPlayer!.mlbbId ?? '',
    );
    final originController = TextEditingController(
      text: _currentPlayer!.origin,
    );
    final paymentNumberController = TextEditingController(
      text: _currentPlayer!.paymentNumber ?? '',
    );
    final paymentNameController = TextEditingController(
      text: _currentPlayer!.paymentName ?? '',
    );

    String? localSelectedMethod = _currentPlayer!.paymentMethod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF163E56),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        bool isSaving = false;

        final List<String> paymentMethods = [
          'DANA',
          'OVO',
          'GOPAY',
          'SHOPEEPAY',
          'BANK BCA',
          'BANK BRI',
          'BANK MANDIRI',
          'BANK BNI',
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Edit Profil Mabar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: nicknameController,
                      label: "Nickname",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: mlbbIdController,
                      label: "ID Mobile Legends",
                      icon: Icons.gamepad_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: originController,
                      label: "Asal Kota",
                      icon: Icons.location_city,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Text(
                      "Pengaturan Akun Pencairan (Tarik Gaji)",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          (localSelectedMethod == null ||
                              localSelectedMethod == '')
                          ? null
                          : localSelectedMethod,
                      dropdownColor: const Color(0xFF163E56),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Pilih E-Wallet / Bank",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF4FA98A),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF4FA98A),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: paymentMethods
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          localSelectedMethod = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: paymentNumberController,
                      label: "Nomor Rekening / No HP E-Wallet",
                      icon: Icons.pin,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: paymentNameController,
                      label: "Nama Pemilik Rekening (Sesuai Aplikasi)",
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FA98A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);

                                Player? updatedPlayer = await _apiService
                                    .updateProfile(
                                      googleId: _currentPlayer!.googleId,
                                      nickname: nicknameController.text,
                                      mlbbId: mlbbIdController.text,
                                      origin: originController.text,
                                      paymentMethod: localSelectedMethod ?? '',
                                      paymentNumber:
                                          paymentNumberController.text,
                                      paymentName: paymentNameController.text,
                                    );

                                if (updatedPlayer != null) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    'user_session',
                                    jsonEncode(updatedPlayer.toJson()),
                                  );

                                  setState(() {
                                    _currentPlayer = updatedPlayer;
                                  });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Profil & Akun Gaji berhasil diupdate!",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  setModalState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Gagal mengupdate profil kawan!",
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "SIMPAN PERUBAHAN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF4FA98A)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF4FA98A)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Widget Helper untuk baris menu/list item data kawan

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
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _currentPlayer == null
              ? const Center(
                  child: Text(
                    "Data profil tidak ditemukan kawan!",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // 1. HEADER (Profile & Koin)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Profile",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF073A4B,
                              ).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                _isLoadingCoins && _currentCoinBalance == 0
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        "$_currentCoinBalance Koin",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),

                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                // Tombol Tambah Koin (+)
                                GestureDetector(
                                  onTap: () async {
                                    // Navigasi ke halaman Top Up
                                    // Kita kirim parameter tambahan agar halaman topup tahu ini hanya untuk isi koin
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TopUpView(),
                                      ),
                                    );

                                    // Setelah kembali, refresh saldonya
                                    _refreshCoins();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // 2. KARTU UTAMA USER INFO
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: AppColors.cardHeaderGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 85,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF163E56),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: FutureBuilder<String>(
                                      // Panggil fungsi backend khusus dengan melempar Google ID player aktif kawan
                                      future: _fetchLatestAvatar(
                                        _currentPlayer!.googleId,
                                      ),
                                      builder: (context, snapshot) {
                                        // 1. KETIKA SEDANG PROSES LOADING AMBIL DATA DARI MYSQL
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        }

                                        // Ambil hasil string URL dari backend kawan
                                        String avatarUrl = snapshot.data ?? "";

                                        // 2. JIKA URL VALID DAN BUKAN PLACEHOLDER YANG TIMEOUT
                                        if (avatarUrl.isNotEmpty &&
                                            !avatarUrl.contains(
                                              "via.placeholder.com",
                                            )) {
                                          return Image.network(
                                            // Tambahkan cache buster biar langsung refresh pasca-edit kawan
                                            "$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}",
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/mlbb.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                          );
                                        }

                                        // 3. FALLBACK JIKA KOSONG / ERROR / MASIH PLACEHOLDER
                                        return Image.asset(
                                          'assets/images/mlbb.png',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentPlayer!.nickname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _currentPlayer!.mlbbId != null &&
                                                _currentPlayer!
                                                    .mlbbId!
                                                    .isNotEmpty
                                            ? "ID MLBB: ${_currentPlayer!.mlbbId}"
                                            : "ID MLBB: Belum Disinkronkan",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            _currentPlayer!.origin,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.redAccent,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF104A61,
                                          ).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "Status : ${_currentPlayer!.status}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 28,
                            left: 70,
                            child: GestureDetector(
                              onTap: () {
                                // 🔥 BUKA HALAMAN EDIT PROFILE DAN OPER DATA DARI USER YANG SEDANG AKTIF KAWAN
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileView(
                                      googleId: _currentPlayer!.googleId,
                                      currentNickname: _currentPlayer!.nickname,
                                      currentOrigin: _currentPlayer!.origin,
                                      currentMlbbId:
                                          _currentPlayer!.mlbbId ?? '',
                                      currentKontak: _currentPlayer!.kontak,
                                      currentAvatarUrl:
                                          _currentPlayer!.avatarUrl ??
                                          'https://via.placeholder.com/150', // Fallback jika null
                                    ),
                                  ),
                                ).then((isUpdated) {
                                  // 🔥 JIKA PROSES SIMPAN BERHASIL (MENGEMBALIKAN SIGNAL TRUE)
                                  if (isUpdated == true) {
                                    // Panggil kembali fungsi memuat profil kawan agar data di UI utama langsung berubah segar!
                                    _loadPlayerProfile();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(152, 0, 0, 0),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/useredit.png',
                                  width: 20,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ), // Fallback aman kawan
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      //kode referral
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/referral.png',
                              width: 60,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dapatkan 5 koin dengan membagikan kode referalmu',
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  //const SizedBox(height: 10),
                                  FutureBuilder<String?>(
                                    future: _fetchReferralCode(),
                                    builder: (context, snapshot) {
                                      // 1. Tentukan apa yang ditampilkan (Loading atau Kode)
                                      String displayCode =
                                          snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? "Loading..."
                                          : (snapshot.data ?? "------");

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Kode Referal : ${_maskReferralCode(displayCode)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              // Jika masih loading, jangan jalankan aksi copy kawan
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting)
                                                return;

                                              bool hasTopup =
                                                  await _checkHasTopup();
                                              if (hasTopup) {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: displayCode,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Kode berhasil disalin kawan!",
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                _showTopupDialog();
                                              }
                                            },
                                            child: const Icon(
                                              Icons.copy,
                                              size: 25,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            onPressed: () {
                                              _showReferralInput(); // <--- Panggil fungsinya di sini kawan!
                                            },
                                            icon: Image.asset(
                                              'assets/images/addref.png',
                                              width: 25,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tombol Upload Bukti
                              // GestureDetector(
                              //   onTap: () async {
                              //     // 1. Tampilkan loading
                              //     showDialog(
                              //       context: context,
                              //       barrierDismissible: false,
                              //       builder: (context) => const Center(
                              //         child: CircularProgressIndicator(
                              //           color: Colors.white,
                              //         ),
                              //       ),
                              //     );

                              //     // 2. Ambil detail pertandingan dari API
                              //     final matchDetails = await _apiService
                              //         .getActiveMatchId(
                              //           googleId: _currentPlayer!.googleId,
                              //         );

                              //     if (!mounted) return;
                              //     Navigator.pop(context); // Tutup loading

                              //     // 3. Validasi: Apakah ada pertandingan aktif?
                              //     if (matchDetails == null) {
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         const SnackBar(
                              //           content: Text(
                              //             "Kamu tidak memiliki pertandingan aktif saat ini kawan!",
                              //           ),
                              //           backgroundColor: Colors.orangeAccent,
                              //         ),
                              //       );
                              //       return;
                              //     }

                              //     // 4. Validasi Kesepakatan (Status Siap)
                              //     final int statusP1 =
                              //         int.tryParse(
                              //           matchDetails['player_1_id_siap']
                              //                   ?.toString() ??
                              //               '0',
                              //         ) ??
                              //         0;
                              //     final int statusP2 =
                              //         int.tryParse(
                              //           matchDetails['player_2_id_siap']
                              //                   ?.toString() ??
                              //               '0',
                              //         ) ??
                              //         0;

                              //     if (statusP1 == 1 && statusP2 == 1) {
                              //       // Jika keduanya sudah siap, lanjut ke halaman upload
                              //       final updatedPlayerFromUpload =
                              //           await Navigator.push(
                              //             context,
                              //             MaterialPageRoute(
                              //               builder: (context) =>
                              //                   UploadReportView(
                              //                     currentPlayer:
                              //                         _currentPlayer!,
                              //                     matchId:
                              //                         matchDetails['match_id']
                              //                             .toString(),
                              //                   ),
                              //             ),
                              //           );

                              //       if (updatedPlayerFromUpload is Player) {
                              //         setState(() {
                              //           _currentPlayer =
                              //               updatedPlayerFromUpload;
                              //         });
                              //       }
                              //     } else {
                              //       // Jika salah satu belum siap
                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         const SnackBar(
                              //           content: Text(
                              //             "Tunggu lawanmu untuk menekan tombol 'Siap' sebelum bisa upload bukti!",
                              //           ),
                              //           backgroundColor: Colors.redAccent,
                              //         ),
                              //       );
                              //     }
                              //   },
                              //   child: Container(
                              //     constraints: BoxConstraints(
                              //       maxWidth:
                              //           MediaQuery.of(context).size.width * 0.7,
                              //     ),
                              //     padding: const EdgeInsets.all(14),
                              //     decoration: BoxDecoration(
                              //       color: const Color(
                              //         0xFF073A4B,
                              //       ).withValues(alpha: 0.4),
                              //       borderRadius: BorderRadius.circular(20),
                              //       border: Border.all(color: Colors.white10),
                              //     ),
                              //     child: Row(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.center,
                              //       mainAxisSize: MainAxisSize.min,
                              //       children: [
                              //         Image.asset(
                              //           'assets/images/upload.png',
                              //           width: 60,
                              //         ),
                              //         const SizedBox(width: 10),
                              //         const Flexible(
                              //           child: Column(
                              //             crossAxisAlignment:
                              //                 CrossAxisAlignment.start,
                              //             mainAxisSize: MainAxisSize.min,
                              //             children: [
                              //               Text(
                              //                 "UPLOAD BUKTI",
                              //                 style: TextStyle(
                              //                   color: Colors.white,
                              //                   fontWeight: FontWeight.bold,
                              //                   fontSize: 15,
                              //                 ),
                              //               ),
                              //               SizedBox(height: 4),
                              //               Text(
                              //                 "Upload bukti pertandingan kalah atau menang disini",
                              //                 style: TextStyle(
                              //                   color: Colors.white70,
                              //                   fontSize: 12,
                              //                   height: 1.2,
                              //                 ),
                              //               ),
                              //             ],
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(width: 12),

                              // Tombol Dokumentasi
                              GestureDetector(
                                onTap: () {
                                  // 🔥 AKSI NAVIGASI MASUK KE HALAMAN DOKUMENTASI
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DokumentasiView(),
                                    ),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF073A4B,
                                    ).withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize
                                        .min, // <-- Mengikuti konten seminimal mungkin
                                    children: [
                                      Image.asset(
                                        'assets/images/documentation.png',
                                        width: 60,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        // <-- Mengubah Expanded menjadi Flexible
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "DOKUMENTASI",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Baca dokumentasi untuk tahu lebih jelas cara mengikuti turnamen di mabarscore",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 12,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FeedbackView(),
                                    ),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF073A4B,
                                    ).withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/feedback.png',
                                        width: 60,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        // <-- Mengubah Expanded menjadi Flexible
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Masukan & Kritikan",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Masukan & Kritikanmu akan membantu kami untuk selalu melakukan perbaikan",
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ),
                                                fontSize: 12,
                                                height: 1.2,
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
                      const SizedBox(height: 20),
                      const Text(
                        "Arenaku",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- SEKARANG MENGGUNAKAN FUTUREBUILDER DINAMIS ---
                      FutureBuilder<List<dynamic>>(
                        future: ApiService().fetchArenaku(
                          googleId: _currentPlayer!.googleId,
                        ),
                        builder: (context, snapshot) {
                          // 1. Kondisi Loading
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            );
                          }

                          // 2. Kondisi Eror / Koneksi Bermasalah
                          if (snapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${snapshot.error}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          // 3. Kondisi Jika Data Kosong
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "Kamu belum terdaftar di arena manapun.",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          // 4. Jika Data Berhasil Diambil, Loop menggunakan ListView / Column
                          final List<dynamic> listArena = snapshot.data!;

                          return ListView.separated(
                            shrinkWrap:
                                true, // Supaya tidak mengambil space tak terbatas di dalam SingleChildScrollView
                            physics:
                                const NeverScrollableScrollPhysics(), // Scroll utama ditangani oleh SingleChildScrollView parent
                            itemCount: listArena.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final arena = listArena[index];
                              return _buildArenaCard(
                                title: arena['title'],
                                status: arena['status'],
                                date: arena['date'],
                                isGugur: arena['is_gugur'],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildArenaCard({
    required String title,
    required String status,
    required String date,
    required bool isGugur,
  }) {
    return GestureDetector(
      onTap: () {
        if (_participationData != null) {
          // Data tersedia, lakukan navigasi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FiveheroDetailView(
                // Gunakan int.parse(data.toString()) agar aman
                arenaId: int.parse(_participationData!['arena_id'].toString()),
                arenaTitle: "Arena ${_participationData!['arena_id']}",
                userCoin: _currentCoinBalance,
                batchId: int.parse(_participationData!['batch_id'].toString()),
              ),
            ),
          );
        } else {
          // Opsional: Berikan feedback jika belum terdaftar di arena
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kamu belum terdaftar di arena manapun"),
            ),
          );
        }
      },

      // {
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                   builder: (context) => FiveheroDetailView(
      //                     arenaId: arenaId,
      //                     arenaTitle:
      //                         cleanTitle, // Kirim title yang sudah bersih kawan
      //                     userCoin: userCoin,
      //                     batchId: batchId,
      //                   ),
      //                 ),
      //               ).then((_) {
      //                 _fetchArenas();
      //               });
      //             },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF073A4B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Ikon Arena
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF2E3A3F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hub_outlined,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Info Teks Arena
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: isGugur ? Colors.white70 : Colors.white,
                      fontWeight: isGugur ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white60,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ikon Panah Diagonal Meluncur ke Kanan Atas
            const Icon(
              Icons.north_east_rounded,
              color: Color(0xFF00E676),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
