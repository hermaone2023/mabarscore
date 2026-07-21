import 'package:flutter/material.dart';

class DetailGambarView extends StatelessWidget {
  final String urlGambar;

  const DetailGambarView({Key? key, required this.urlGambar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Background hitam pekat khas galeri foto kawan
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        // InteractiveViewer inilah yang otomatis menangani pinch-to-zoom kawan
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          minScale: 0.5, // Batas maksimal diperkecil
          maxScale: 4.0, // Batas maksimal diperbesar (4x lipat)
          child: Image.network(
            urlGambar,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Gagal memuat gambar utuh kawan",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
