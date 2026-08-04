import 'dart:ui';

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
  final int maxDurationSeconds = 5 * 60; // 5 menit
  final PageController _pageController = PageController();
  String _kategoriHeroKesepakatan = "Memuat...";

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
      // 💡 Kembalikan ke ukuran normal statik awal (lebar 550, tinggi 660)
      //await FlutterOverlayWindow.resizeOverlay(550, 660, true);
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
        await FlutterOverlayWindow.resizeOverlay(380, 600, true);
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });

        if (_secondsElapsed >= maxDurationSeconds) {
          _stopAndSaveToGallery(); // atau _stopAndSaveToGallery() sesuai method Anda
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
    } catch (e) {
      print("Error mengirim sinyal stop dari overlay: $e");
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
    super.dispose();
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
                            ? '${_formatTime(_secondsElapsed)} / 05:00'
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
                      // 🔥 Tombol Cepat Rekam / Stop di Mode Minimize
                      SizedBox(
                        height: 24,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRecording
                                ? Colors.red
                                : Colors.teal.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            if (isRecording) {
                              _stopAndSaveToGallery();
                            } else {
                              _onStartOverlayButtonClicked();
                            }
                          },
                          icon: Icon(
                            isRecording
                                ? Icons.stop
                                : Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 10,
                          ),
                          label: Text(
                            isRecording ? 'Stop' : 'Rekam',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Tombol Maximized / Restore
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
                      const SizedBox(width: 6),
                      // Tombol Close
                      InkWell(
                        onTap: () async {
                          if (isRecording) {
                            await _stopAndSaveToGallery();
                          } else {
                            await FlutterOverlayWindow.closeOverlay();
                          }
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
                  ),
                ],
              )
            :
              // 🔥 TAMPILAN NORMAL (LENGKAP)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER & KONTROL NAVIGASI (Minimize, Maximize/Restore, Close) ---
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
                          // Tombol Minimize (Garis mendatar)
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
                          // Tombol Maximize / Kotak
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
                          // Tombol Close (Silang)
                          InkWell(
                            onTap: () async {
                              if (isRecording) {
                                await _stopAndSaveToGallery();
                              } else {
                                await FlutterOverlayWindow.closeOverlay();
                              }
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
                        ? 'Merekam : ${_formatTime(_secondsElapsed)} / 05:00'
                        : 'Panel Perekaman',
                    style: TextStyle(
                      color: isRecording ? Colors.redAccent : Colors.tealAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- TOMBOL UTAMA (Mulai Rekam / Stop & Simpan) ---
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: isRecording
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _stopAndSaveToGallery(),
                            icon: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 14,
                            ),
                            label: const Text(
                              'Stop & Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _onStartOverlayButtonClicked(),
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
                          title: Text(
                            "Baca Aturan",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          children: [
                            // 1. Kurangi tinggi SizedBox agar lebih rapat ke atas
                            SizedBox(
                              height: 100,
                              child: PageView(
                                controller: _pageController,
                                physics: NeverScrollableScrollPhysics(),
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
                                      child: Column(
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
                                            "- Klik Tombol Mulai Rekam saat hanya mulai bertanding .",
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
                                      child: Column(
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
                                            "- Wajib gunakan arena Middle Lane\n"
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
                                  //halamn 3
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
                                          Text(
                                            "3. Kesepakatan (Hal 3 dari 3)",
                                            style: TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "Kamu telah melakukan kesepakatan dengan lawan tandingmu untuk menggunakan kategori Hero : $_kategoriHeroKesepakatan",
                                            style: TextStyle(
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

                            // 2. Buat padding tombol seminimal mungkin agar menempel rapi di bawah teks
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
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets
                                              .zero, // 💡 Hilangkan padding bawaan tombol
                                          minimumSize: Size(0, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: Icon(
                                          Icons.arrow_back,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        label: Text(
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
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets
                                              .zero, // 💡 Hilangkan padding bawaan tombol
                                          minimumSize: Size(0, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: Colors.tealAccent,
                                        ),
                                        label: Text(
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
