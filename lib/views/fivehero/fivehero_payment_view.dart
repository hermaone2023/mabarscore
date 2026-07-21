import 'package:flutter/material.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart'; // Pastikan path ApiService kamu benar kawan
import 'package:mabarscore/views/fivehero/fivehero_top_up_view.dart';

class FiveheroPaymentView extends StatefulWidget {
  final int
  arenaId; // KAWAN: Wajib dititipkan agar bisa dimasukkan ke database otomatis
  final String arenaTitle;
  final int userCoin;
  final String googleId;
  final int batchId;

  const FiveheroPaymentView({
    Key? key,
    required this.arenaId, // Tambahkan di konstruktor kawan
    required this.arenaTitle,
    required this.userCoin,
    required this.googleId,
    required this.batchId,
  }) : super(key: key);

  @override
  State<FiveheroPaymentView> createState() => _FiveheroPaymentViewState();
}

class _FiveheroPaymentViewState extends State<FiveheroPaymentView> {
  bool _isLoading =
      false; // State untuk efek loading saat memproses transaksi kawan

  // KAWAN: Fungsi untuk memproses pendaftaran langsung ke backend PHP
  Future<void> _processRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // KAWAN: Sekarang kita gunakan Google ID asli yang dikirim dari halaman detail!
      final String currentGoogleId = widget.googleId;
      print("[DEBUG API CALL] Tepat sebelum menembak API joinArena:");
      print("-> Mengirim Google ID: $currentGoogleId");
      print("-> Mengirim Arena ID : ${widget.arenaId}");
      print(
        "-> Mengirim BATCH ID : ${widget.batchId} <--- (Ayo kawan, pastikan ini '2' di log!)",
      );

      final response = await ApiService().joinArena(
        googleId: currentGoogleId,
        arenaId: widget.arenaId,
        batchId: widget.batchId,
      );

      setState(() {
        _isLoading = false;
      });

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  "Pendaftaran berhasil! Semoga juara kawan! 🏆",
            ),
            backgroundColor: const Color(0xFF59C393),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Gagal mendaftar kawan."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan koneksi kawan: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // 🔥 PERINTAH PRINT DEBUGS TINGKAT DEWA (TAKTIK PERTAMA)
    // Langsung tembak cetakan saat halaman ini pertama kali dimuat kawan!
    print("");
    print(
      "----------------------------------------------------------------------------------",
    );
    print("🎯 [DEBUG ARENA MASUK PAYMENT VIEW] 🎯");
    print("Mengecek Operan Estafet Data Batch ID kawan:");
    print("");
    print(
      "1. Final BATCH ID Tertangkap: ${widget.batchId}  <--- (Cek ini harus angka 2 kawan!)",
    );
    print("2. Arena ID Tertangkap  : ${widget.arenaId}");
    print("3. Google ID Tertangkap : ${widget.googleId}");
    print("4. User Coin Dititipkan  : ${widget.userCoin}");
    print("5. Judul Arena          : ${widget.arenaTitle}");
    print(
      "----------------------------------------------------------------------------------",
    );
    print("");
  }

  @override
  Widget build(BuildContext context) {
    final int currentCoin = widget.userCoin;
    const int entryFee = 50;
    final int remainingCoin = currentCoin - entryFee;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // AREA UTAMA INTERFACE INVOICE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  // APP BAR ELEGAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Biaya Pendaftaran",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // TIKET INVOICE ELEGAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        // BAGIAN ATAS TIKET
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 28,
                            horizontal: 20,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF59C393),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  widget.arenaTitle.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "50K",
                                style: TextStyle(
                                  fontSize: 68,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -1,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                "Koin Turnamen",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // GARIS DOTTED POTONGAN TIKET
                        Container(
                          color: const Color(0xFF59C393),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 10,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D4C5C),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Flex(
                                      direction: Axis.horizontal,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      mainAxisSize: MainAxisSize.max,
                                      children: List.generate(
                                        (constraints.constrainWidth() / 10)
                                            .floor(),
                                        (index) => const SizedBox(
                                          width: 5,
                                          height: 2,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                width: 10,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5661),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // BAGIAN BAWAH TIKET (RINCIAN STRUK SALDO)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                "Metode Pembayaran",
                                "Brankas Koin",
                                isGold: true,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(
                                  color: Colors.white10,
                                  thickness: 1,
                                ),
                              ),
                              _buildDetailRow(
                                "Saldo Koin Anda",
                                "$currentCoin Koin",
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                "Biaya Registrasi",
                                "$entryFee Koin",
                                isRed: true,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(
                                  color: Colors.white10,
                                  thickness: 1,
                                ),
                              ),
                              _buildDetailRow(
                                "Sisa Saldo Brankas",
                                remainingCoin >= 0
                                    ? "$remainingCoin Koin"
                                    : "Koin Kurang (${remainingCoin.abs()} Koin)",
                                isTotal: true,
                                isRed: remainingCoin < 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // TOMBOL PROSES PEMBAYARAN / TOP UP
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 25),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null // Matikan tombol jika proses sedang berjalan kawan
                            : () {
                                if (currentCoin >= entryFee) {
                                  // JALUR KONDISI A: Koin cukup, langsung daftarkan otomatis kawan!
                                  _processRegistration();
                                } else {
                                  // JALUR KONDISI B: Koin kurang, oper arenaId target agar nanti pasca-topup bisa daftar otomatis!
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FiveheroTopUpView(
                                        targetArenaId: widget.arenaId,
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentCoin >= entryFee
                              ? const Color(0xFF59C393)
                              : Colors.amber,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          currentCoin >= entryFee
                              ? "REGISTRASI SEKARANG" // Diubah sesuai keinginan alur kamu kawan
                              : "TOP UP KOIN SEKARANG",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // LOADING OVERLAY (EFEK PUTAR NEON JIKA BACKEND SEDANG BEKERJA)
              if (_isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF59C393),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isGold = false,
    bool isRed = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? Colors.white : Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: (isTotal || isGold || isRed)
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isRed
                  ? Colors.redAccent
                  : isGold
                  ? Colors.amber
                  : isTotal
                  ? const Color(0xFF59C393)
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
