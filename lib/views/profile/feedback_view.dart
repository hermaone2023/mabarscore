import 'package:flutter/material.dart';
import 'package:mabarscore/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Sesuaikan

class FeedbackView extends StatefulWidget {
  const FeedbackView({Key? key}) : super(key: key);

  @override
  _FeedbackViewState createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final _feedbackController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tulis sesuatu dulu kawan!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('google_id');
    String? email = prefs.getString('email');

    setState(() => _isLoading = true);

    bool sukses = await _apiService.kirimMasukan(
      userId ?? 'unknown',
      email ?? 'guest',
      _feedbackController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sukses) {
      Navigator.pop(context, true); // Kirim sinyal sukses kembali
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Terima kasih atas masukannya kawan!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengirim, periksa koneksi ya."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF163E56), // Sesuaikan background
      appBar: AppBar(
        title: const Text(
          "Beri Masukan",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Saran, kritik, atau keluhanmu sangat berharga...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA98A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitFeedback,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "KIRIM MASUKAN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
