import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'dart:async';
import 'package:mabarscore/views/auth/login_view.dart';
import 'package:mabarscore/views/auth/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mabarscore/views/main_navigation.dart';

// Handler background FCM Notif
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// --- ENTRY POINT UTAMA UNTUK OVERLAY NAVIGASI MELAYANG ---
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  // TAMBAHKAN BARIS INI AGAR PLUGIN NATIVE TERDAFTAR DI ISOLATE OVERLAY
  DartPluginRegistrant.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: FloatingRecorderWidget(),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print(
      "Catatan: Pastikan google-services.json sudah terpasang kawan. Error: $e",
    );
  }

  // 1. KUNCI AUTO-LOGIN
  bool isLoggedIn = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? userSession = prefs.getString('user_session');
    if (userSession != null && userSession.isNotEmpty) {
      isLoggedIn = true;
    }
  } catch (e) {
    print("Gagal memeriksa sesi di main kawan: $e");
  }

  // Konfigurasi Layar
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MabarScoreApp(isLoggedIn: isLoggedIn));
}

class MabarScoreApp extends StatefulWidget {
  final bool isLoggedIn;
  const MabarScoreApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<MabarScoreApp> createState() => _MabarScoreAppState();
}

class _MabarScoreAppState extends State<MabarScoreApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    // 1. Notifikasi saat aplikasi terbuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        "Notifikasi masuk saat aplikasi dibuka: ${message.notification?.title}",
      );
    });

    // 2. Notifikasi saat user klik notifikasi (saat aplikasi di background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User mengklik notifikasi: ${message.data}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MabarScore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(isLoggedIn: widget.isLoggedIn),
      routes: {
        '/login': (context) => const LoginView(),
        '/main': (context) => const MainNavigation(),
        '/fivehero_view': (context) => const MainNavigation(),
        '/detail_pertandingan': (context) => const MainNavigation(),
      },
    );
  }
}

// --- WIDGET PANEL MELAYANG DENGAN KONTROL PEREKAMAN 5 MENIT ---
class FloatingRecorderWidget extends StatefulWidget {
  const FloatingRecorderWidget({Key? key}) : super(key: key);

  @override
  State<FloatingRecorderWidget> createState() => _FloatingRecorderWidgetState();
}

class _FloatingRecorderWidgetState extends State<FloatingRecorderWidget> {
  bool isRecording = false;
  bool isMinimized = false; // 🔥 Status untuk mode minimize
  // Ukuran normal overlay Anda
  final double _normalWidth = 280;
  final double _normalHeight = 320;

  // Ukuran saat minimized (misalnya hanya ikon / bar kecil)
  final double _minimizedWidth = 270;
  final double _minimizedHeight = 70;
  bool isExpandedRules = false; // 🔥 Status collapsible aturan pertandingan
  Timer? _timer;
  int _secondsElapsed = 0;
  final int maxDurationSeconds = (1 * 60) + 25; // 5 menit
  final PageController _pageController = PageController();
  String _kategoriHeroKesepakatan = "Memuat...";

  Future<void> minimizeAppToHome() async {
    try {
      // Perintah native Android untuk menekan tombol Home secara virtual
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
      print("Berhasil meminimalkan aplikasi ke home kawan!");
    } catch (e) {
      print("Gagal kembali ke home: $e");
    }
  }

  @override
  void initState() {
    _loadKategoriHero();
    super.initState();
  }

  Future<void> _loadKategoriHero() async {
    // Memanggil dari ApiService yang sudah rapi
    String hasil = await ApiService.getKategoriHeroKesepakatan();
    setState(() {
      _kategoriHeroKesepakatan = hasil;
    });
  }

  // Fungsi Toggle Minimize / Restore Ukuran Overlay
  Future<void> _toggleMinimize() async {
    setState(() {
      isMinimized = !isMinimized;
    });

    if (isMinimized) {
      // 💡 Ukuran saat dikecilkan (Minimize) - sesuaikan jika perlu
      await FlutterOverlayWindow.resizeOverlay(
        _minimizedWidth.toInt(),
        _minimizedHeight.toInt(),
        true,
      );
    } else {
      // 💡 Kembalikan ke ukuran normal statik awal
      await FlutterOverlayWindow.resizeOverlay(
        _normalWidth.toInt(),
        _normalHeight.toInt(),
        true,
      );
    }
  }

  Future<void> _onStartOverlayButtonClicked() async {
    try {
      print("Overlay: Mengirim sinyal start ke halaman utama...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('start_recording_signal', true);

      setState(() {
        isRecording = true;
        _secondsElapsed = 0;
      });

      // Tetap gunakan ukuran statik normal yang sama
      if (!isMinimized) {
        await FlutterOverlayWindow.resizeOverlay(
          _normalWidth.toInt(),
          _normalHeight.toInt(),
          true,
        );
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });

        if (_secondsElapsed >= maxDurationSeconds) {
          _stopAndSaveToGallery();
        }
      });
    } catch (e) {
      print("Gagal mengirim sinyal start: $e");
    }
  }

  Future<void> _stopAndSaveToGallery() async {
    _timer?.cancel();
    try {
      print("Overlay: Mengirim sinyal stop ke halaman utama...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stop_recording_signal', true);

      setState(() {
        isRecording = false;
        isMinimized = false;
      });

      await FlutterOverlayWindow.closeOverlay();

      final intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: 'com.mabarscore.app',
        componentName: 'com.mabarscore.app.MainActivity',
        flags: <int>[
          0x10000000, // FLAG_ACTIVITY_NEW_TASK
          0x00020000, // FLAG_ACTIVITY_SINGLE_TOP
        ],
      );
      await intent.launch();
    } catch (e) {
      print("Error menghentikan perekaman dari overlay: $e");
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showPrePermissionDialog(VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.tealAccent.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          elevation: 12,
          child: SingleChildScrollView(
            // 🔥 Bungkus dengan SingleChildScrollView di sini
            padding: const EdgeInsets.all(
              16.0,
            ), // Sedikit dikurangi dari 20 agar lebih longgar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Konfirmasi Perekaman",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12),

                // Pesan Edukasi / Pengantar
                const Text(
                  "Izinkan perekaman layar, lalu ketuk 'Mulai Sekarang' pada peringatan sistem agar pertandingan mulai terekam",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Aksi
                // Tombol Aksi yang fleksibel agar tidak overflow
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white60,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Batal
                        },
                        child: const Text(
                          "Batal",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog pengantar
                          onConfirm(); // Jalankan fungsi rekam layar & overlay
                        },
                        child: const Text(
                          "Lanjutkan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 550,
        height: 650,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 30, 30).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecording ? Colors.redAccent : Colors.tealAccent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isMinimized
            ?
              // 🔥 TAMPILAN SAAT DI-MINIMIZE (Kecil & Ringkas)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: isRecording ? Colors.red : Colors.tealAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording
                            ? '${_formatTime(_secondsElapsed)} / 05:25'
                            : 'Panel Siap',
                        style: TextStyle(
                          color: isRecording ? Colors.redAccent : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 🔥 TOMBOL REKAM / STOP: Hanya tampil jika TIDAK sedang merekam (atau diblok saat minimized & recording)
                      if (!isRecording) ...[
                        SizedBox(
                          height: 24,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.withValues(
                                alpha: 0.6,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              _onStartOverlayButtonClicked();
                            },
                            icon: const Icon(
                              Icons.fiber_manual_record,
                              color: Colors.white,
                              size: 10,
                            ),
                            label: const Text(
                              'Rekam',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                      ] else ...[
                        // Jika sedang merekam dan minimized, tampilkan teks info pengaman/gembok kecil
                        const Icon(
                          Icons.lock,
                          color: Colors.redAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Locked",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 15),
                      ],

                      // Tombol Maximized / Restore (Selalu ada untuk membuka kembali panel utama)
                      InkWell(
                        onTap: _toggleMinimize,
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.open_in_full,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ),

                      // 🔥 TOMBOL CLOSE: Hanya tampil jika TIDAK sedang merekam
                      if (!isRecording) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () async {
                            await FlutterOverlayWindow.closeOverlay();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              )
            :
              // 🔥 TAMPILAN NORMAL (LENGKAP)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER & KONTROL NAVIGASI ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MabarScore Arena',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: _toggleMinimize,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.remove,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: _toggleMinimize,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.crop_square,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (!isRecording)
                            InkWell(
                              onTap: () async {
                                await FlutterOverlayWindow.closeOverlay();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Status Teks Perekaman
                  Text(
                    isRecording
                        ? 'Merekam : ${_formatTime(_secondsElapsed)} / 05:25'
                        : 'Panel Perekaman',
                    style: TextStyle(
                      color: isRecording ? Colors.redAccent : Colors.tealAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- TOMBOL UTAMA ---
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: isRecording
                        ? Container(
                            // ... (kode container saat recording locked tetap sama)
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _showPrePermissionDialog(() async {
                                // 1. Panggil minimize ke home terlebih dahulu (atau bersamaan)
                                // agar aplikasi langsung minimize/ke home di background
                                if (context.mounted) {
                                  minimizeAppToHome();
                                }

                                // 2. Jalankan fungsi utama perekaman & overlay
                                _onStartOverlayButtonClicked();
                              });
                            },
                            icon: const Icon(
                              Icons.fiber_manual_record,
                              color: Colors.white,
                              size: 14,
                            ),
                            label: const Text(
                              'Mulai Rekam',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),

                  // --- COLLAPSIBLE: KETETAPAN ATURAN PERTANDINGAN & KESEPAKATAN ---
                  Expanded(
                    child: ListView(
                      children: [
                        ExpansionTile(
                          initiallyExpanded: false,
                          title: const Text(
                            "Baca Aturan",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          children: [
                            SizedBox(
                              height: 100,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  // Halaman 1
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 6.0,
                                        right: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "1. Aturan Pertama (Hal 1 dari 2)",
                                            style: TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "- Biarkan app mabarscore tetap aktif\n"
                                            "- Buka Game Mobile Legends\n"
                                            "- Klik Tombol Mulai Rekam saat mulai bertanding.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Halaman 2
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 6.0,
                                        right: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "2. Aturan Kedua (Hal 2 dari 3)",
                                            style: TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "- Waktu Tanding 5 menit setelah Mulai Rekam diklik\n"
                                            "- Pemenang ditentukan jumlah KILL terbanyak.",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Halaman 3
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 6.0,
                                        right: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "3. Kesepakatan (Hal 3 dari 3)",
                                            style: TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Kamu telah melakukan kesepakatan dengan lawan tandingmu untuk menggunakan kategori Hero : $_kategoriHeroKesepakatan",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 0.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        label: const Text(
                                          "Sebelumnya",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: Colors.tealAccent,
                                        ),
                                        label: const Text(
                                          "Selanjutnya",
                                          style: TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
