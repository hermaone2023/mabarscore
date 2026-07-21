import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <--- TAMBAHKAN INI UNTUK kDebugMode KAWAN
// <--- TAMBAHKAN INI UNTUK MOCK AUTH CREDENTIAL
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mabarscore/core/constants/app_colors.dart';
import 'package:mabarscore/core/services/api_service.dart'; // <--- IMPOR API SERVICE KAWAN
import 'package:mabarscore/core/models/player_model.dart'; // <--- IMPOR MODEL PLAYER KAWAN
import 'package:mabarscore/views/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;

  // Inisialisasi Google Sign In kawan
  // Masukkan Web Client ID dari Firebase tadi ke sini kawan agar otentikasinya terkunci rapat
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "679942692535-5565564aum4g6u9k81dk237pksg5bfa0.apps.googleusercontent.com",
    scopes: ['email'],
  );

  // Inisialisasi ApiService kawan
  final ApiService _apiService = ApiService();

  // FUNGSI KHUSUS EMULATOR TESTING (BYPASS NATIVE GOOGLE POP-UP)
  // FUNGSI KHUSUS EMULATOR TESTING (100% BYPASS FIREBASE AUTH & SECURITY MANIFEST)
  // Future<void> _handleEmulatorMockSignIn() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     print(
  //       "🚀 Menyiapkan 250 akun simulasi massal MabarScore yang sinkron dengan database...",
  //     );

  //     // 🔥 FIX KAWAN: Populasi dinaikkan jadi 250 dan format string disamakan dengan backend PHP
  //     List<Map<String, String>> mockPlayers = List.generate(250, (index) {
  //       int id = index + 1;
  //       return {
  //         'googleId': 'sim_google_id_$id', // 💡 Harus sama dengan isi database
  //         'nickname': 'Player_Sim_$id',
  //         'email':
  //             'player_sim_$id@mabarscore.com', // 💡 Harus sama dengan isi database
  //         'avatarUrl': 'https://via.placeholder.com/150',
  //       };
  //     });

  //     setState(() {
  //       _isLoading = false;
  //     });

  //     // 2. TAMPILKAN BOTTOM SHEET UTK MEMILIH AKUN
  //     if (!mounted) return;
  //     showModalBottomSheet(
  //       context: context,
  //       backgroundColor: const Color(0xff1A1A1A),
  //       shape: const RoundedRectangleBorder(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       builder: (BuildContext context) {
  //         return Container(
  //           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  //           // Menggunakan tinggi 80% layar agar scroller 250 player nyaman digunakan kawan
  //           height: MediaQuery.of(context).size.height * 0.8,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(
  //                 child: Container(
  //                   width: 40,
  //                   height: 4,
  //                   margin: const EdgeInsets.only(bottom: 16),
  //                   decoration: const BoxDecoration(
  //                     color: Colors.grey,
  //                     borderRadius: BorderRadius.all(Radius.circular(10)),
  //                   ),
  //                 ),
  //               ),
  //               const Text(
  //                 "Pilih Akun Simulasi (1-250)",
  //                 style: TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //               const Padding(
  //                 padding: EdgeInsets.only(top: 4, bottom: 16),
  //                 child: Text(
  //                   "Pilih salah satu dari 250 player untuk bertindak sebagai user tersebut kawan.",
  //                   style: TextStyle(color: Colors.grey, fontSize: 12),
  //                 ),
  //               ),
  //               const Divider(color: Colors.white24),
  //               Expanded(
  //                 child: ListView.builder(
  //                   itemCount: mockPlayers.length,
  //                   itemBuilder: (context, index) {
  //                     final player = mockPlayers[index];
  //                     return ListTile(
  //                       leading: CircleAvatar(
  //                         backgroundColor: Colors.blueGrey,
  //                         child: Text(
  //                           "${index + 1}",
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ),
  //                       title: Text(
  //                         player['nickname']!,
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       subtitle: Text(
  //                         player['email']!,
  //                         style: const TextStyle(
  //                           color: Colors.grey,
  //                           fontSize: 12,
  //                         ),
  //                       ),
  //                       trailing: const Icon(
  //                         Icons.arrow_forward_ios,
  //                         size: 14,
  //                         color: Colors.white30,
  //                       ),
  //                       onTap: () async {
  //                         Navigator.pop(context);

  //                         // Eksekusi kirim data bypass login ke backend PHP kawan
  //                         _executeDirectBypassLogin(
  //                           googleId: player['googleId']!,
  //                           nickname: player['nickname']!,
  //                           email: player['email']!,
  //                           avatarUrl: player['avatarUrl']!,
  //                         );
  //                       },
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  //   } catch (error) {
  //     print("Error showing picker: $error");
  //     setState(() => _isLoading = false);
  //   }
  // }

  // 3. FUNGSI EKSEKUSI LOGIN MASUK KE DASHBOARD SETELAH AKUN DIPILIH
  // Future<void> _executeDirectBypassLogin({
  //   required String googleId,
  //   required String nickname,
  //   required String email,
  //   required String avatarUrl,
  // }) async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // 1. Ambil token terbaru sebelum login bypass
  //     String? fcmToken;
  //     try {
  //       fcmToken = await FirebaseMessaging.instance.getToken();
  //     } catch (e) {
  //       fcmToken = "";
  //     }
  //     print("🧪 Mengirim data token $email langsung ke server PHP...");

  //     final Player? player = await _apiService.loginOrRegisterWithGoogle(
  //       googleId: googleId,
  //       nickname: nickname,
  //       email: email,
  //       avatarUrl: avatarUrl,
  //       fcmToken: fcmToken ?? "",
  //     );

  //     if (player != null) {
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('user_session', jsonEncode(player.toJson()));
  //       await prefs.setString('google_id', googleId);

  //       print("🎯 Sukses login lokal sebagai ${player.nickname}");

  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               "🎯 Masuk sebagai ${player.nickname} (${player.email})",
  //             ),
  //             backgroundColor: Colors.greenAccent,
  //             duration: const Duration(seconds: 2),
  //           ),
  //         );

  //         // Langsung arahkan masuk ke Dashboard navigasi utama kawan
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MainNavigation()),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     print("Gagal menembak backend PHP: $e");
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  // FUNGSI UTAMA: Login & Ambil Token Notifikasi kawan (Sudah Kebal Eror FCM)
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignIn.signOut();
      // 1. Proses autentikasi akun Google kawan
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        print("User Terautentikasi: ${googleUser.displayName}");
        print("Email User: ${googleUser.email}");

        // 2. AMBIL TOKEN UNTUK KEBUTUHAN NOTIFIKASI (FCM Token) kawan
        String? fcmToken;

        try {
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          NotificationSettings settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            fcmToken = await messaging.getToken().timeout(
              const Duration(seconds: 3),
            );
            print("================== FCM TOKEN ANDA ==================");
            print(fcmToken);
            print("====================================================");
          }
        } catch (fcmError) {
          print(
            "Aman kawan, FCM tidak tersedia tetapi login jalan terus. Detail: $fcmError",
          );
          fcmToken = "";
        }

        // 3. TEMBAK DATA KE BACKEND PHP KAWAN
        final Player? player = await _apiService.loginOrRegisterWithGoogle(
          googleId: googleUser.id,
          nickname: googleUser.displayName ?? "Player Mabar",
          email: googleUser.email,
          avatarUrl: googleUser.photoUrl ?? "",
          fcmToken: fcmToken,
        );

        if (player != null) {
          // ---- SIMPAN DATA PLAYER SECARA LOKAL KAWAN ----
          final prefs = await SharedPreferences.getInstance();
          final playerJsonString = jsonEncode(player.toJson());
          await prefs.setString('user_session', playerJsonString);
          await prefs.setString('google_id', googleUser.id);
          print("Sesi player berhasil disimpan kawan!");

          // 4. Pindah ke Halaman Utama Dashboard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Selamat datang kembali, ${player.nickname}!"),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Otentikasi server gagal atau akun Anda ditangguhkan kawan!",
                ),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    } catch (error) {
      print("Error login Google Utama kawan: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal login menggunakan akun Google kawan!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainBackgroundGradient,
          image: DecorationImage(
            image: AssetImage('assets/images/bglogin.png'),
            fit: BoxFit.cover,
            //opacity: 0.05,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            key: const ValueKey('login_padding'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // LOGO ATAU IKON APLIKASI MABARSCORE
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logoms2.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),

                // JUDUL & SLOGAN
                const Text(
                  "MABARSCORE",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "Online Tournament Provider",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Siap jadi juara? Turnamen Mobile Legends di MabarScore kini terbuka untuk umum! Saatnya buktikan skill-mu, taklukkan lawan, dan bawa pulang hadiah besarnya!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),

                const Spacer(),

                // TOMBOL LOGIN GOOGLE NYATA & PREMIUM
                SizedBox(
                  width: double.infinity,
                  height: 56, // Sedikit lebih tinggi agar terasa lebih mantap
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: _isLoading
                          ? 0
                          : 6, // Bayangan hilang saat ditekan/loading
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // Rounded yang lebih modern
                      ),
                      // Menambahkan efek splash agar ada feedback saat ditekan
                      splashFactory: InkRipple.splashFactory,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black87,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google.png',
                                height: 22,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Masuk dengan Google",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight
                                      .w600, // Semibold lebih rapi untuk tombol
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // 2. Footer dengan kontras yang lebih baik agar terlihat pro
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ), // Tambahkan padding biar tidak terlalu mepet kiri-kanan
                  child: Text(
                    "Dengan masuk, Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi MabarScore.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, // Sedikit lebih besar agar nyaman dibaca
                      color: Colors.white.withValues(
                        alpha: 0.6,
                      ), // Alpha 0.6 lebih terbaca daripada 0.4
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
