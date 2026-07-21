import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // 1. Warna Latar Belakang / Background Utama (Gelap Esport)
  static const Color backgroundTop = Color(
    0xFF0D5C53,
  ); // Hijau toska tua bagian atas gradasi
  static const Color backgroundDark = Color(
    0xFF031B19,
  ); // Hijau-hitam pekat latar belakang utama warkop
  static const Color scaffoldBg = Color(
    0xFF0A3631,
  ); // Warna dasar scaffold dasar

  // 2. Warna Komponen Utama / Card / Container
  static const Color cardBg = Color(
    0xFF08413B,
  ); // Warna dasar kotak/card player & arena
  static const Color navBarBg = Color(
    0xFF708D8A,
  ); // Warna abu-abu pudar di navbar melayang
  static const Color navBarIconUnselected = Color(
    0xFF263238,
  ); // Ikon non-aktif di navbar

  // 3. Warna Aksen & Tombol (Neon / Highlights)
  static const Color neonGreen = Color(
    0xFF0FF000,
  ); // Warna panah hijau dan status aktif
  static const Color cyanAccent = Color(
    0xFF00F0FF,
  ); // Warna aksen teks/piala highlight
  static const Color joinButton = Color(
    0xFF0F5A52,
  ); // Warna tombol panjang "Join Arena"

  // 4. Warna Teks Terikat UI
  static const Color textPrimary =
      Colors.white; // Teks utama (Judul, Nama Player)
  static const Color textSecondary = Color(
    0xFF90A4AE,
  ); // Teks keterangan (Status, Subtitle)
  static const Color textMuted = Color(
    0xFFB0BEC5,
  ); // Teks deskripsi reguler berukuran kecil

  // 5. Gradasi Global (Sesuai Visual Desain Anda)
  static const LinearGradient mainBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundDark],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF147A6F), Color(0xFF083832)],
  );
}
