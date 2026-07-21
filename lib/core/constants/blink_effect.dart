import 'package:flutter/material.dart';

class BlinkingIndicator extends StatefulWidget {
  const BlinkingIndicator({Key? key}) : super(key: key);

  @override
  State<BlinkingIndicator> createState() => _BlinkingIndicatorState();
}

class _BlinkingIndicatorState extends State<BlinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Mengatur durasi kedipan kawan (1000 milidetik / 1 detik)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animasi perubahan opacity dari 0.2 (redup) ke 1.0 (terang) kawan
    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Membuka animasi secara berulang (bolak-balik otomatis kawan)
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose(); // Wajib didispose agar tidak leak memori
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFFE4C367), // Warna emas bawaan kawan
          shape: BoxShape.circle,
          boxShadow: [
            // Tambahan sedikit efek glow/sinar tipis biar keren kawan!
            BoxShadow(color: Color(0xFFE4C367), blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
