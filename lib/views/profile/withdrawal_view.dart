import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/models/player_model.dart';
import 'package:mabarscore/core/services/api_service.dart';

class WithdrawalView extends StatefulWidget {
  final Player currentPlayer;
  final Function(Player)
  onWithdrawalSuccess; // Callback untuk mengupdate profile utama kawan

  const WithdrawalView({
    Key? key,
    required this.currentPlayer,
    required this.onWithdrawalSuccess,
  }) : super(key: key);

  @override
  State<WithdrawalView> createState() => _WithdrawalViewState();
}

class _WithdrawalViewState extends State<WithdrawalView> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _coinController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  // Rate Konversi Koin kawan (Misal: 1 Koin = Rp 1.000)
  final int _coinRate = 1000;
  int _calculatedRupiah = 0;
  bool _isProcessing = false;

  // Daftar Pilihan Fleksibel kawan
  String? _selectedMethod;
  final List<String> _paymentMethods = [
    'DANA',
    'OVO',
    'GOPAY',
    'SHOPEEPAY',
    'BANK BCA',
    'BANK BRI',
    'BANK MANDIRI',
    'BANK BNI',
  ];

  @override
  void initState() {
    super.initState();
    _coinController.addListener(_updateRupiahCalculation);
  }

  void _updateRupiahCalculation() {
    final enteredCoins = int.tryParse(_coinController.text) ?? 0;
    setState(() {
      _calculatedRupiah = enteredCoins * _coinRate;
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _submitWithdrawal() async {
    if (!_formKey.currentState!.validate() || _selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silakan lengkapi form penarikan kawan!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final coinsToDeduct = int.parse(_coinController.text);

    // Validasi saldo koin di sisi aplikasi kawan
    if (coinsToDeduct > widget.currentPlayer.coinsBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saldo koin kawan tidak mencukupi!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    Player? updatedPlayer = await _apiService.requestWithdrawal(
      googleId: widget.currentPlayer.googleId,
      coinsDeducted: coinsToDeduct,
      amountRupiah: _calculatedRupiah,
      bankName: _selectedMethod!,
      accountNumber: _accountNumberController.text,
      accountName: _accountNameController.text,
    );

    setState(() => _isProcessing = false);

    if (updatedPlayer != null) {
      // Simpan sesinya ke local storage kawan
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(updatedPlayer.toJson()));

      // Panggil callback agar halaman profil kawan ikut terupdate koinnya kawan
      widget.onWithdrawalSuccess(updatedPlayer);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF163E56),
            title: const Text(
              "Sukses Kawan!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Penarikan $_calculatedRupiah via $_selectedMethod berhasil diajukan. Mohon tunggu proses transfer dari admin kawan.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog kawan
                  Navigator.pop(context); // Kembali ke halaman profil kawan
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Color(0xFF4FA98A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengajukan penarikan kawan, coba lagi!"),
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
          "Tarik Gaji Mabar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF163E56),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Saldo Saat Ini kawan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FA98A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Saldo Koin Kamu:",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${widget.currentPlayer.coinsBalance} Koin",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Dropdown Fleksibel Bank / E-Wallet kawan
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  dropdownColor: const Color(0xFF163E56),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Pilih E-Wallet / Bank Tujuan",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF4FA98A),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4FA98A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedMethod = value),
                  validator: (value) => value == null
                      ? 'Wajib memilih metode penarikan kawan!'
                      : null,
                ),
                const SizedBox(height: 16),

                // Input Jumlah Koin kawan
                TextFormField(
                  controller: _coinController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Jumlah Koin Yang Ingin Ditarik",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.monetization_on,
                      color: Color(0xFF4FA98A),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4FA98A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Jumlah koin wajib diisi kawan!';
                    if (int.tryParse(value) == null || int.parse(value) <= 0)
                      return 'Masukkan jumlah koin yang valid kawan!';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Live Preview Nominal Rupiah kawan
                Text(
                  "Estimasi diterima: Rp $_calculatedRupiah (Rate: 1 Koin = Rp $_coinRate)",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Input Nomor Rekening atau Nomor HP E-Wallet kawan
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Nomor Rekening / No HP E-Wallet",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.pin, color: Color(0xFF4FA98A)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4FA98A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nomor tujuan wajib diisi kawan!'
                      : null,
                ),
                const SizedBox(height: 16),

                // Input Nama Pemilik Rekening kawan
                TextFormField(
                  controller: _accountNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Nama Pemilik Akun / Rekening (Sesuai Aplikasi)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF4FA98A),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4FA98A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama pemilik wajib diisi kawan!'
                      : null,
                ),
                const SizedBox(height: 30),

                // Tombol Submit kawan
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
                    onPressed: _isProcessing ? null : _submitWithdrawal,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "AJUKAN PENARIKAN",
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
    );
  }
}
