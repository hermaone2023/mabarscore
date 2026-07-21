class Player {
  final int? id;
  final String googleId;
  final String nickname;
  final String email;
  final String? mlbbId;
  final String origin;
  final String kontak;
  final String? avatarUrl;
  final int coinsBalance;
  final String? fcmToken;
  final String status;
  final String? referralCode;

  // ---- TAMBAHAN 3 VARIABEL BARU UNTUK AKUN GAJI KAWAN ----
  final String? paymentMethod;
  final String? paymentNumber;
  final String? paymentName;

  Player({
    this.id,
    required this.googleId,
    required this.nickname,
    required this.email,
    this.mlbbId,
    required this.origin,
    required this.kontak,
    this.avatarUrl,
    required this.coinsBalance,
    this.fcmToken,
    required this.status,
    this.referralCode,
    // Masukkan ke constructor utama kawan
    this.paymentMethod,
    this.paymentNumber,
    this.paymentName,
  });

  // Fungsi factory yang sudah dimodifikasi kawan
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      // ID Aman kawan
      id: json['id'] != null
          ? int.tryParse(json['id'].toString()) ?? json['id']
          : null,

      googleId: json['google_id'] ?? '',
      nickname: json['nickname'] ?? 'Player Mabar',
      email: json['email'] ?? '',
      mlbbId: json['mlbb_id'],
      origin: json['origin'] ?? 'Indonesia - Makassar',
      kontak: json['kontak'] ?? '+62',
      avatarUrl: json['avatar_url'],

      // Coins Balance Aman kawan
      coinsBalance: json['coins_balance'] != null
          ? (int.tryParse(json['coins_balance'].toString()) ?? 0)
          : 0,

      fcmToken: json['fcm_token'],
      status: json['status'] ?? 'Player aktif',
      referralCode: json['referral_code'],

      // Petakan field baru dari JSON Backend database kawan
      paymentMethod: json['payment_method'],
      paymentNumber: json['payment_number'],
      paymentName: json['payment_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_id': googleId,
      'nickname': nickname,
      'email': email,
      'mlbb_id': mlbbId,
      'origin': origin,
      'kontak': kontak,
      'avatar_url': avatarUrl,
      'coins_balance': coinsBalance,
      'fcm_token': fcmToken,
      'status': status,
      // Masukkan ke map json agar awet tersimpan di SharedPreferences kawan
      'payment_method': paymentMethod,
      'payment_number': paymentNumber,
      'payment_name': paymentName,
    };
  }

  Player copyWith({
    int? id,
    String? googleId,
    String? nickname,
    String? email,
    String? mlbbId,
    String? origin,
    String? kontak,
    String? avatarUrl,
    int? coinsBalance,
    String? fcmToken,
    String? status,
    String? paymentMethod,
    String? paymentNumber,
    String? paymentName,
  }) {
    return Player(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      mlbbId: mlbbId ?? this.mlbbId,
      origin: origin ?? this.origin,
      kontak: kontak ?? this.kontak,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      fcmToken: fcmToken ?? this.fcmToken,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentName: paymentName ?? this.paymentName,
    );
  }
}
