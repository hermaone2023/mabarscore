import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DokumentasiView extends StatefulWidget {
  const DokumentasiView({super.key});

  @override
  State<DokumentasiView> createState() => _DokumentasiViewState();
}

class _DokumentasiViewState extends State<DokumentasiView> {
  // Status untuk membuka/menutup accordion petunjuk kawan
  bool _isExpanded = false;

  Future<void> _launchWhatsApp() async {
    // Ganti dengan nomor WhatsApp admin kamu (gunakan format internasional tanpa +)
    final String phoneNumber = "6281234567890";
    final String message = "Halo Admin, saya butuh bantuan terkait MabarScore.";

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      // Tampilkan error jika WhatsApp tidak terinstall atau gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal membuka WhatsApp. Pastikan WhatsApp sudah terinstall.",
          ),
        ),
      );
    }
  }

  Future<void> _bukaVideoTutorial() async {
    // Ganti URL di bawah ini dengan link video tutorial Mabarscore milikmu kawan
    final Uri url = Uri.parse(
      'https://youtu.be/SpuajDDBQwA?si=Y3p28qzXI0d_UXNc',
    );

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // Berhasil membuka YouTube / Browser eksternal kawan
      } else {
        throw 'Tidak dapat membuka $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka video tutorial kawan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradasi Latar Belakang Sesuai Mockup UI Mabarscore kawan
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D4661), // Biru tua gelap atas
              Color(0xFF3AC394), // Hijau terang bawah
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. HEADER BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Dokumentasi",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Balancer space agar judul tepat di tengah
                  ],
                ),
              ),

              // 2. KONTEN UTAMA (SCROLLABLE)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Teks Deskripsi Mabarscore kawan
                      Text(
                        "Mabarscore adalah platform penyedia turnamen online bagi para gamer Mobile Legend Bang Bang untuk membuktikan diri sebagai Pro Player dan layak untuk mendapatkan reward yang luar biasa",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // reward
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF145E6A).withValues(
                            alpha: 0.4,
                          ), // Warna semi transparan gelap
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Image.asset('assets/images/reward.png', width: 60),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp. 7.000. 000',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      136,
                                      255,
                                      0,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Total Hadiah Finalis',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 3. ACCORDION / EXPANSION DROPDOWN kawan
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF145E6A).withValues(
                            alpha: 0.4,
                          ), // Warna semi transparan gelap
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Theme(
                          // Menghilangkan border bawaan ExpansionTile kawan
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _isExpanded = expanded;
                              });
                            },
                            title: const Text(
                              "Bagaimana caranya mengikuti turnamen di mabarscore ?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            trailing: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_right_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // POIN 1
                                    _buildStepItem(
                                      "Lengkapi data profile kamu untuk kemudahan administrasi penyelenggara turnamen",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 2
                                    _buildStepItem(
                                      "Masuk ke halaman Fivehero Arena, Fivehero arena adalah sebuah slot atau arena tempat calon player untuk bergabung dalam grup turnamen dan mendapatkan lawan tanding jumlah maksimal player dalam satu arena adalah 5 player, jumlah Fivehero arena di turnamen ini adalah 50",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 3 (DENGAN SUB-ATURAN KESEPAKATAN) kawan
                                    _buildStepItem(
                                      "Saat ini turnamen yang dipertandingkan adalah Mobile Legend BY ONE atau 1 vs 1 dengan aturan main yang fleksibel atau sesuai kesepakatan kedua pemain yang akan bertanding dalam halaman DETAIL PERTANDINGAN sudah disediakan room chat untuk melakukan kesepakatan dan kesepakatan yang bisa dilakukan adalah sebagai berikut:",
                                    ),

                                    // --- AWAL SUB-ATURAN POIN 3 ---
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 30,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Sub Aturan Hero
                                          _buildSubRuleItem(
                                            "Aturan Hero dan Item",
                                            "• Bebas: Kedua pemain boleh memakai hero apa saja yang mereka kuasai.\n• Sama (Mirror Match): Kedua pemain wajib memakai hero yang sama persis (misalnya sesama hero Assassins seperti Saber atau Marksman).\n• Larangan Item: Biasanya disepakati larangan untuk membeli item Roam agar permainan tetap adil secara ekonomi.",
                                          ),
                                          const SizedBox(height: 10),

                                          // Sub Aturan Area
                                          _buildSubRuleItem(
                                            "Aturan Area dan Jalur Bertarung (Lane)",
                                            "• Mid Lane Saja: Pertarungan hanya berpusat di jalur tengah atau mid lane.\n• Dilarang Clear Minion di Side Lane: Pemain dilarang membersihkan minion di jalur atas maupun bawah sampai turret utama hancur.",
                                          ),
                                          const SizedBox(height: 10),

                                          // Sub Aturan Recall
                                          _buildSubRuleItem(
                                            "Aturan Recall dan Jungling",
                                            "• Dilarang Recall: Pemain tidak boleh kembali ke markas (base) untuk mengisi HP atau mana, kecuali saat mati.\n• Dilarang Farming: Pemain dilarang membunuh creep hutan (monster jungle). Semua emas dan poin exp murni didapat dari minion dan kill.",
                                          ),
                                          const SizedBox(height: 10),

                                          // Sub Aturan Win Condition
                                          _buildSubRuleItem(
                                            "Syarat Menentukan Kemenangan (Win Condition)",
                                            "• Sistem Poin Kill: Pemain yang berhasil mencapai jumlah kill tertentu (misal: 3 kali kill terlebih dahulu) keluar sebagai pemenang.\n• Hancurkan Turret: Pemain yang lebih dulu menghancurkan turret di mid lane dinyatakan menang.\n• Batas Waktu (Time Limit): Jika waktu habis tanpa mencapai jumlah kill, pemenang dihitung dari jumlah kill terbanyak atau gold tertinggi.",
                                          ),
                                          const SizedBox(height: 10),

                                          // Sub Aturan Tambahan
                                          _buildSubRuleItem(
                                            "Aturan Tambahan",
                                            "• No Chat All: Pemain dilarang mengetik pesan yang mengejek (trashtalk) di all chat.\n• Surrender: Pemain yang kalah jumlah kill sesuai kesepakatan harus langsung melakukan surrender.",
                                          ),
                                        ],
                                      ),
                                    ),

                                    // --- AKHIR SUB-ATURAN POIN 3 ---
                                    const SizedBox(height: 4),

                                    // POIN 4
                                    _buildStepItem(
                                      "Pilih salah satu Fivehero area 1 sd 50 yang jumlah playernya belum penuh",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 5
                                    _buildStepItem(
                                      "Jika kamu telah memilih Fivehero arena yang masih kosong atau belum full klik tombol \"Join Fivehero arena\".",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 6
                                    _buildStepItem(
                                      "Karena jumlah player dalam 1 arena adalah 5 atau ganjil sementara skema tanding adalah:\n   - Match 1 (M1) = player1 vs player2\n   - Match 2 (M2) = player3 vs player4\n   - Match 3 (M3) = Juara M1 vs Juara M2\n   - Match 4 (M4) = Juara M3 vs player5\ndimana player 5 mendapatkan hak istimewa yaitu hanya main 1 kali dalam penentuan juara arena, maka posisi player 5 akan diacak oleh sistem secara adil yang player harus melakukan persetujuan.",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 7
                                    _buildStepItem(
                                      "Syarat mutlak untuk bisa mengikuti turnamen ini adalah harus memiliki minimal 50 koin dan jika koin kamu tidak mencukupi kamu wajib melakukan topup minimal 50K (Rp.50.000), Topup koin dilakukan langsung dalam aplikasi mabarscore ini",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 8
                                    _buildStepItem(
                                      "Jika topup kamu berhasil kamu akan langsung tergabung dalam Fivehero arena yang kamu telah pilih",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 9
                                    _buildStepItem(
                                      "Kamu dapat langsung melakukan tanding jika jumlah player dalam arena yang kamu pilih sudah cukup 5 player dan secara acak sistem akan mempertemukanmu dengan lawan yang juga sudah diacak dan kamu dapat melakukan kesepakatan terlebih dahulu sebelum melakukan tanding Mobile Legend BY ONE di game MLBB masing masing.",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 10
                                    _buildStepItem(
                                      "Setelah melakukan pertandingan kedua pemain wajib melapor ke aplikasi mabarscore di halaman profile, pemain yang menang dan kalah wajib melapor dan memilih tombol menang jika menang dan tombol kalah jika kalah kemudian masukkan screenshot hasil tanding dan pilih tombol upload.",
                                    ),
                                    const SizedBox(height: 14),

                                    // POIN 11
                                    _buildStepItem(
                                      "Jika kedua pemain dalam melakukan upload laporan sama-sama mengklaim hasil tanding maka dinyatakan sengketa dan hasil tanding akan diperiksa oleh admin atau dewan juri untuk menentukan siapa pemenangnya",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 4. TOMBOL VIDEO TUTORIAL (INTERAKTIF)
                      InkWell(
                        onTap: () {
                          // Tambahkan aksi buka link video / YouTube tutorialmu disini kawan
                          _bukaVideoTutorial();
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF196A74).withValues(
                              alpha: 0.5,
                            ), // Custom tint teal sesuai mockup
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(
                                0xFF3AC394,
                              ).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Ikon Kamera Video Kustom kawan
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D4661,
                                  ).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons
                                      .video_collection_rounded, // Berbentuk balon video chat/tutorial
                                  color: Colors.blueAccent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Teks Judul & Subtitle kawan
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "VIDEO TUTORIAL",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Nonton video tutorialnya",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Panah Kanan penunjuk kawan
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          _launchWhatsApp();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF145E6A).withValues(
                              alpha: 0.4,
                            ), // Warna semi transparan gelap
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/adminsupport.png',
                                width: 50,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SUPPORT ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Kamu butuh bantuan terkait mabarscore silahkan hubungi admin kami pada jam kerja',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
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
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk menyusun item baris instruksi beserta ikon bulat oranye kawan
  Widget _buildStepItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bullet Ikon Bulat Logomu kawan (Gunakan logo mabarscore atau ikon bawaan yang mirip)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors
                  .orangeAccent, // Mengikuti warna emblem bulat oranye di mockup kawan
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.yellow, Colors.orange, Colors.deepOrange],
              ),
            ),
            child: const Icon(
              Icons
                  .sports_esports_rounded, // Detail kecil ikon game di tengahnya kawan
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Deskripsi Teks langkah instruksi
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubRuleItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "- $title",
          style: const TextStyle(
            color: Colors.orangeAccent, // Memberi warna pembeda emas kawan
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
