import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadProfileMlbbView extends StatefulWidget {
  final String googleId;
  const UploadProfileMlbbView({super.key, required this.googleId});

  @override
  State<UploadProfileMlbbView> createState() => _UploadProfileMlbbViewState();
}

class _UploadProfileMlbbViewState extends State<UploadProfileMlbbView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  String _selectedRank = 'Warrior';
  bool _isLoading = false;

  final List<String> _ranks = [
    'Warrior',
    'Elite',
    'Master',
    'Grandmaster',
    'Epic',
    'Legend',
    'Mythic',
    'Mythical Glory',
    'Mythical Immortal',
  ];

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse(
      "https://donorta.tech/apimabarscore/save_profile_mlbb.php",
    );

    try {
      final response = await http.post(
        url,
        body: {
          'google_id': widget.googleId,
          'nickname': _nameController.text,
          'mlbb_id': _idController.text,
          'rank': _selectedRank,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final prefs = await SharedPreferences.getInstance();
          String? sessionString = prefs.getString('user_session');
          if (sessionString != null) {
            Map<String, dynamic> session = jsonDecode(sessionString);
            session['mlbb_id'] =
                _idController.text; // Update MLBB ID di session
            await prefs.setString('user_session', jsonEncode(session));
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Data profil berhasil disimpan!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception(data['message'] ?? "Gagal menyimpan.");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D4661), Color(0xFF3AC394)],
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/bgml.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Text(
                                  "Verifikasi akun ML BB",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            const Text(
                              "Masukkan data akun Mobile Legend Bang Bang (ML BB) kamu untuk kemudahan administrasi penyedia turnamen",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Fields
                            _buildLabel("Nama akun ML"),
                            _buildTextField(
                              _nameController,
                              "Contoh: JagoanGaming",
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("ID akun ML (Server)"),
                            _buildTextField(
                              _idController,
                              "Contoh: 123456789 (1234)",
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Rank ML"),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF145E6A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedRank,
                                dropdownColor: const Color(0xFF0D4661),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(color: Colors.white),
                                items: _ranks
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedRank = val!),
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Spacer(),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D4661),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "SIMPAN",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
    ),
  );
  Widget _buildTextField(TextEditingController controller, String hint) =>
      TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF145E6A),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v!.isEmpty ? "Tidak boleh kosong" : null,
      );
}
