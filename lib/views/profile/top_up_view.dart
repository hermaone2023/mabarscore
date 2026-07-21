import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TopUpView extends StatefulWidget {
  const TopUpView({Key? key}) : super(key: key);

  @override
  State<TopUpView> createState() => _TopUpViewState();
}

class _TopUpViewState extends State<TopUpView> {
  int _selectedPackageIndex = -1;
  Timer? _paymentCheckTimer;
  String _selectedPaymentMethod =
      'Midtrans Secure Payment (QRIS/Dana/Ovo/Bank)';
  bool _isProcessingPayment = false;
  int _currentCoins = 0;
  bool _isLoadingCoins = true;
  String? _activeOrderId;
  bool _isWaitingForPayment = false;

  final List<Map<String, dynamic>> _topUpPackages = [
    {'coins': 50, 'price': 'Rp 50.000', 'numeric_price': 50000},
    {'coins': 100, 'price': 'Rp 100.000', 'numeric_price': 100000},
    {'coins': 200, 'price': 'Rp 200.000', 'numeric_price': 200000},
    {'coins': 300, 'price': 'Rp 300.000', 'numeric_price': 300000},
    {'coins': 500, 'price': 'Rp 500.000', 'numeric_price': 500000},
    {'coins': 1000, 'price': 'Rp 1.000.000', 'numeric_price': 1000000},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDatabaseCoins();
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDatabaseCoins() async {
    if (!mounted) return;
    setState(() => _isLoadingCoins = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? googleId = prefs.getString('google_id');
      if (googleId != null && googleId.isNotEmpty) {
        int updatedCoins = await ApiService().getCoinsBalance(
          googleId: googleId,
        );
        await prefs.setInt('coins_balance', updatedCoins);
        if (mounted) setState(() => _currentCoins = updatedCoins);
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi koin kawan: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCoins = false);
    }
  }

  Future<void> _checkActivePaymentStatus({bool isAutoCheck = false}) async {
    if (_activeOrderId == null) return;
    try {
      // ⚠️ Pastikan di ApiService kamu ada method khusus untuk cek transaksi umum
      final transactionResult = await ApiService().checkTransactionStatus(
        orderId: _activeOrderId!,
      );
      final statusTransaksi = (transactionResult['status'] ?? '')
          .toString()
          .toUpperCase();

      if (statusTransaksi == 'SUCCESS' || statusTransaksi == 'SETTLEMENT') {
        _paymentCheckTimer?.cancel();
        _fetchDatabaseCoins(); // Refresh saldo
        if (mounted) {
          setState(() => _isWaitingForPayment = false);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Top Up Berhasil!'),
              content: const Text('Koin kamu sudah bertambah kawan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error check status: $e");
    }
  }

  String _formatNumber(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(number).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Top Up Koin', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCurrentBalanceCard(),
            const SizedBox(height: 24),
            _isWaitingForPayment
                ? _buildWaitingPaymentCard()
                : _buildMainTopUpForm(),
          ],
        ),
      ),
    );
  }

  // --- Widget helper tetap sama, hanya sesuaikan tombol pay ---
  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: (_selectedPackageIndex == -1 || _isProcessingPayment)
          ? null
          : () async {
              setState(() => _isProcessingPayment = true);
              try {
                final prefs = await SharedPreferences.getInstance();
                final String? googleId = prefs.getString('google_id');
                final selectedPkg = _topUpPackages[_selectedPackageIndex];

                // ⚠️ PANGGIL API BARU KAMU DI SINI
                final result = await ApiService().createTopUpTransactionProfile(
                  // Pastikan method ini ada di ApiService
                  googleId: googleId!,
                  coins: selectedPkg['coins'],
                  amount: selectedPkg['numeric_price'],
                  paymentMethod: _selectedPaymentMethod,
                );

                if (result['redirect_url'] != null) {
                  await launchUrl(
                    Uri.parse(result['redirect_url']),
                    mode: LaunchMode.externalApplication,
                  );
                  setState(() {
                    _activeOrderId = result['order_id'];
                    _isWaitingForPayment = true;
                  });
                  _paymentCheckTimer = Timer.periodic(
                    const Duration(seconds: 5),
                    (_) => _checkActivePaymentStatus(isAutoCheck: true),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Eror: $e')));
              } finally {
                setState(() => _isProcessingPayment = false);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00E676), // Warna hijau khas pembayaran
        foregroundColor: Colors.black87, // Warna teks
        elevation: _isProcessingPayment ? 0 : 5, // Shadow hilang saat loading
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ), // Lebih rounded tapi tetap pro
        ),
        minimumSize: const Size(
          double.infinity,
          50,
        ), // Lebar penuh agar mudah diklik
      ),
      child: _isProcessingPayment
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            )
          : const Text(
              'Lanjutkan Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    );
  }

  // ... (Sertakan widget _buildCurrentBalanceCard, _buildPackageGrid, dll dari FiveheroTopUpView)
  Widget _buildCurrentBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Koin Kamu',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              _isLoadingCoins
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _formatNumber(_currentCoins),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(width: 6),
              const Text(
                'Coins',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPaymentCard() {
    final selectedPkg = _topUpPackages[_selectedPackageIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF6C63FF),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menunggu Pembayaran kawan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan selesaikan tagihan Anda di browser eksternal murnimu kawan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order ID:', style: TextStyle(color: Colors.black54)),
              Text(
                _activeOrderId ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paket:',
                style: TextStyle(color: Colors.black54),
              ),
              Text(
                '${selectedPkg['coins']} Coins',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bayar:',
                style: TextStyle(color: Colors.black54),
              ),
              Text(
                selectedPkg['price'],
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Selesai & Cek Status Koin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              onPressed: _checkActivePaymentStatus,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _paymentCheckTimer
                  ?.cancel(); // ◄ Matikan timer di sini kawan kawan
              setState(() {
                _isWaitingForPayment = false;
                _selectedPackageIndex = -1;
              });
            },
            child: const Text(
              'Pilih Paket Lain',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTopUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Paket Koin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildPackageGrid(),
        const SizedBox(height: 24),
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodDropdown(),
        const SizedBox(height: 40),
        _buildPayButton(),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPaymentMethod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C63FF)),
          items: <String>['Midtrans Secure Payment (QRIS/Dana/Ovo/Bank)']
              .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 15)),
                );
              })
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPaymentMethod = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPackageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _topUpPackages.length,
      itemBuilder: (context, index) {
        final package = _topUpPackages[index];
        final isSelected = _selectedPackageIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPackageIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${package['coins']} Coins',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    package['price'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
