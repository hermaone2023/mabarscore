import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mabarscore/views/auth/login_view.dart';
import 'package:mabarscore/views/auth/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mabarscore/views/main_navigation.dart';

// Handler background FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
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
      // Di sini kamu bisa tambahkan logika alert atau refresh UI jika perlu
    });

    // 2. Notifikasi saat user klik notifikasi (saat aplikasi di background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User mengklik notifikasi: ${message.data}");
      // Jika butuh navigasi khusus, tambahkan logika Navigator di sini
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
      //home: widget.isLoggedIn ? const MainNavigation() : const LoginView(),
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
