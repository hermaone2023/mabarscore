import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mabarscore/core/models/player_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Domain server produksi kawan yang sudah HTTPS mantap!
  static const String baseUrl = "https://donorta.tech/apimabarscore";

  Future<Player?> loginOrRegisterWithGoogle({
    required String googleId,
    required String nickname,
    required String email,
    required String avatarUrl,
    String? fcmToken,
  }) async {
    final url = Uri.parse("$baseUrl/auth_google.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "google_id": googleId,
          "nickname": nickname,
          "email": email,
          "avatar_url": avatarUrl,
          "fcm_token": fcmToken,
        }),
      );

      // KUNCI PERUBAHAN: Menerima kode 200 (OK) dan 201 (Created / Register Baru) kawan!
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == true) {
          // Berhasil parse ke Objek Player kawan
          print("Response API Sukses kawan: ${responseData['message']}");
          return Player.fromJson(responseData['data']);
        } else {
          print("Gagal Auth Backend kawan: ${responseData['message']}");
          return null;
        }
      } else {
        // Jika eror 500 atau lainnya terjadi, cetak juga isi body erornya kawan agar mudah dilacak
        print("Server Error kawan: ${response.statusCode}");
        print("Detail Error Server: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error koneksi ApiService kawan: $e");
      return null;
    }
  }

  Future<Player?> updateProfile({
    required String googleId,
    required String nickname,
    required String mlbbId,
    required String origin,
    required String paymentMethod, // Pastikan parameter ini ada kawan
    required String paymentNumber, // Pastikan parameter ini ada kawan
    required String paymentName, // Pastikan parameter ini ada kawan
  }) async {
    final url = Uri.parse("$baseUrl/update_profile.php");

    // LOG UNTUK UTK CEK DATA SEBELUM DIKIRIM (Cek di Debug Console kawan)
    print(
      "Kirim ke PHP -> Method: $paymentMethod, Number: $paymentNumber, Name: $paymentName",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "google_id": googleId,
          "nickname": nickname,
          "mlbb_id": mlbbId,
          "origin": origin,
          // KUNCI UTAMA: Key ini harus huruf kecil semua & pakai underscore (_)
          // agar sama persis dengan yang dibaca oleh file PHP kawan!
          "payment_method": paymentMethod,
          "payment_number": paymentNumber,
          "payment_name": paymentName,
        }),
      );

      print(
        "Respon PHP: ${response.body}",
      ); // Log untuk melihat balasan dari server kawan

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          return Player.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      print("Error updateProfile kawan: $e");
      return null;
    }
  }

  Future<Player?> requestWithdrawal({
    required String googleId,
    required int coinsDeducted,
    required int amountRupiah,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final url = Uri.parse("$baseUrl/request_withdrawal.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "google_id": googleId,
          "coins_deducted": coinsDeducted,
          "amount_rupiah": amountRupiah,
          "bank_name": bankName,
          "account_number": accountNumber,
          "account_name": accountName,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          return Player.fromJson(
            responseData['data'],
          ); // Mengembalikan data user dengan koin yang sudah berkurang
        }
      }
      return null;
    } catch (e) {
      print("Error ApiService saat request withdrawal kawan: $e");
      return null;
    }
  }

  // Tambahkan fungsi ini di dalam class ApiService kawan
  Future<int> getCoinsBalance({required String googleId}) async {
    final url = Uri.parse("$baseUrl/get_coins.php?google_id=$googleId");

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          // Ambil nilai 'coins_balance' dari response data kawan
          return int.tryParse(
                responseData['data']['coins_balance'].toString(),
              ) ??
              0;
        }
      }
      return 0; // Fallback default jika status false kawan
    } catch (e) {
      print("Error getCoinsBalance di ApiService kawan: $e");
      return 0; // Fallback aman jika koneksi bermasalah
    }
  }

  // 1. FUNGSI TOP UP BARU (Mendukung Otomatisasi Arena kawan)
  Future<Map<String, dynamic>> createTopUpTransaction({
    required String googleId,
    required String orderId,
    required int coins,
    required int amount,
    required String paymentMethod,
    int? targetArenaId, // KUNCI BARU: Tambahkan parameter opsional ini kawan
  }) async {
    final url = Uri.parse("$baseUrl/create_payment.php");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "google_id": googleId,
              "order_id": orderId,
              "coins": coins,
              "amount": amount,
              "payment_method": paymentMethod,
              "target_arena_id":
                  targetArenaId, // KUNCI BARU: Dikirim ke PHP kawan (bisa bernilai null jika topup biasa)
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("DETAIL EROR SERVER 500: ${response.body}");
        try {
          final errorData = jsonDecode(response.body);
          return {
            "status": false,
            "message":
                errorData['message'] ??
                "Terjadi kesalahan internal server (500) kawan.",
          };
        } catch (_) {
          return {
            "status": false,
            "message":
                "Server mengalami gangguan internal (Status: ${response.statusCode}) kawan.",
          };
        }
      }
    } catch (e) {
      print("Error createTopUpTransaction kawan: $e");
      return {"status": false, "message": "Koneksi bermasalah kawan"};
    }
  }

  // 2. FUNGSI JOIN ARENA BARU (Menggunakan JSON murni kawan)
  Future<Map<String, dynamic>> joinArena({
    required String googleId,
    required int arenaId,
    required int batchId, // 🔥 KAWAN: Tambahkan parameter batchId di sini
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/join_arena.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'google_id': googleId,
              'arena_id': arenaId,
              'batch_id':
                  batchId, // 🔥 KAWAN: Kirimkan batch_id ke JSON backend
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Gagal terhubung ke server (${response.statusCode}) kawan',
        };
      }
    } catch (e) {
      print("Error joinArena di ApiService kawan: $e");
      return {'status': 'error', 'message': 'Terjadi kesalahan kawan: $e'};
    }
  }

  // ==================== AREA LIGA / FIVEHERO ARENA ====================

  Future<List<dynamic>> getArenasData({
    required int batchId,
    required String googleId,
    int? round, // 🔥 KAWAN: Tambahkan parameter round opsional di sini
  }) async {
    // 🔥 Jika parameter round dikirim, kita ikut selipkan ke dalam query string URL kawan
    String urlString =
        "$baseUrl/get_arenas.php?batch_id=$batchId&google_id=$googleId";
    if (round != null) {
      urlString += "&round=$round";
    }

    final url = Uri.parse(urlString);

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['data'];
        }
      }
      return [];
    } catch (e) {
      print("Error getArenasData di ApiService kawan: $e");
      return [];
    }
  }

  /// KAWAN: Fungsi mengambil daftar player yang sudah join & status kepesertaan user
  Future<Map<String, dynamic>?> getArenaDetails({
    required int arenaId,
    required int batchId,
    required String googleId,
  }) async {
    // KAWAN: Menggunakan queryParameters menjaga karakter spesial agar tidak merusak URL
    final url = Uri.parse("$baseUrl/get_arena_details.php").replace(
      queryParameters: {
        "arena_id": arenaId.toString(),
        "batch_id": batchId.toString(),
        "google_id": googleId,
      },
    );

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print("Error getArenaDetails di ApiService kawan: $e");
      return null;
    }
  }

  // ==================== CEK STATUS TRANSAKSI TOP UP KAWAN ====================

  /// Fungsi untuk memeriksa status spesifik dari order_id di tabel topup_transactions
  Future<Map<String, dynamic>> checkTransactionStatus({
    required String orderId,
  }) async {
    final url = Uri.parse("$baseUrl/check_transaction.php?order_id=$orderId");

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message":
              "Gagal membaca status server (${response.statusCode}) kawan",
        };
      }
    } catch (e) {
      print("Error checkTransactionStatus di ApiService kawan: $e");
      return {
        "status": "error",
        "message": "Koneksi bermasalah saat cek transaksi kawan",
      };
    }
  }

  Future<Map<String, dynamic>?> uploadMatchReport({
    required String matchId,
    required String googleId,
    required String
    statusClaim, // Berisi teks 'Menang' atau 'Kalah' dari tombol UI kawan
    required File screenshotFile,
  }) async {
    try {
      var uri = Uri.parse("$baseUrl/upload_match_report.php");
      var request = http.MultipartRequest('POST', uri);

      // Tambahkan text fields kawan
      request.fields['match_id'] = matchId;
      request.fields['google_id'] = googleId;
      request.fields['status_claim'] =
          statusClaim; // 🔥 Dikirim sebagai status_claim agar pas dengan PHP kawan

      // Ambil stream file gambar kawan
      var stream = http.ByteStream(screenshotFile.openRead());
      var length = await screenshotFile.length();

      var multipartFile = http.MultipartFile(
        'screenshot',
        stream,
        length,
        filename: path.basename(screenshotFile.path),
      );

      request.files.add(multipartFile);

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      return jsonDecode(responseString);
    } catch (e) {
      print("Error uploadMatchReport kawan: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveMatchId({
    required String googleId,
  }) async {
    final url = Uri.parse("$baseUrl/get_active_match.php?google_id=$googleId");

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Cek apakah status success dan data tersedia
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // Mengembalikan seluruh objek data (termasuk match_id, status siap, dll)
          return responseData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("Error getActiveMatchDetails di ApiService kawan: $e");
      return null;
    }
  }

  // Tambahkan ini di dalam class ApiService kawan
  Future<int> getActiveBatchId() async {
    final url = Uri.parse("$baseUrl/get_active_batch.php");

    try {
      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          // Ambil batch_id hasil query database kawan
          return int.tryParse(responseData['data']['batch_id'].toString()) ?? 1;
        }
      }
      return 1; // Fallback jika response gagal kawan
    } catch (e) {
      print("Error getActiveBatchId di ApiService kawan: $e");
      return 1; // Fallback aman jika koneksi bermasalah
    }
  }

  Future<List<dynamic>> fetchArenaku({required String googleId}) async {
    final String url = "$baseUrl/get_arenaku.php?google_id=$googleId";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          return responseData['data'];
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception("Gagal terhubung ke server (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Eror: Koneksi bermasalah kawan");
    }
  }

  Future<Map<String, dynamic>> createTopUpTransactionProfile({
    required String googleId,
    required int coins,
    required int amount,
    required String paymentMethod,
  }) async {
    // ⚠️ Ganti dengan URL endpoint yang kamu gunakan di server
    final String url = '$baseUrl/create_payment_profile.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'google_id': googleId,
          'coins': coins.toString(),
          'amount': amount.toString(),
          'payment_method': paymentMethod,
        },
      );

      if (response.statusCode == 200) {
        // Mengonversi response JSON dari PHP menjadi Map
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Gagal membuat transaksi, status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint("Error saat memanggil API TopUp: $e");
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  Future<Map<String, dynamic>?> getBatchStandings(String batchId) async {
    try {
      // Menghubungkan ke file backend yang sudah kita buat
      final response = await http.get(
        Uri.parse("$baseUrl/get_batch_standings.php?batch_id=$batchId"),
      );

      if (response.statusCode == 200) {
        // Mengubah response JSON string menjadi Map Flutter
        return json.decode(response.body);
      } else {
        print("Gagal memuat data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Terjadi error: $e");
      return null;
    }
  }

  // Tambahkan fungsi ini di dalam class ApiService
  Future<Map<String, dynamic>?> getPlayerParticipation(String googleId) async {
    try {
      // Pastikan baseUrl sudah didefinisikan di class ApiService
      final response = await http.get(
        Uri.parse("$baseUrl/get_player_participation.php?google_id=$googleId"),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Gagal mengambil data partisipasi: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error saat memanggil API partisipasi: $e");
      return null;
    }
  }

  // Contoh perbaikan di ApiService
  Future<bool> kirimMasukan(
    String userId,
    String email,
    String feedbackText,
  ) async {
    final url = Uri.parse(
      "$baseUrl/save_feedback.php",
    ); // Pastikan path-nya benar

    try {
      print("Mencoba kirim ke: $url");
      var response = await http.post(
        url,
        body: {
          'user_id': userId,
          'email': email,
          'feedback_text': feedbackText,
        },
      );

      // LOG INI SANGAT PENTING
      print("Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Cek apakah body kosong
        if (response.body.isEmpty) {
          print("Error: Body respons kosong!");
          return false;
        }

        final data = jsonDecode(response.body);
        return data['status'] == true;
      } else {
        print("Server error dengan status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error saat parsing JSON atau koneksi: $e");
    }
    return false;
  }

  static Future<String> getKategoriHeroKesepakatan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int arenaId = prefs.getInt('match_arena_id') ?? 0;
      final int batchId = prefs.getInt('match_batch_id') ?? 0;
      final int round = prefs.getInt('match_round') ?? 0;
      final int matchNumber = prefs.getInt('match_number') ?? 0;

      if (arenaId == 0 || batchId == 0) {
        return "Data pertandingan tidak ditemukan";
      }

      // Menggunakan baseUrl yang sudah didefinisikan di ApiService
      final response = await http.post(
        Uri.parse('$baseUrl/kategori_hero.php'),
        body: {
          'arena_id': arenaId.toString(),
          'batch_id': batchId.toString(),
          'round': round.toString(),
          'match_number': matchNumber.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return data['kategori_hero'] ?? '-';
        } else {
          return '-';
        }
      } else {
        return "Gagal memuat";
      }
    } catch (e) {
      return "Error koneksi";
    }
  }
}
