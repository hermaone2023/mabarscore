import 'package:flutter/material.dart';
import 'package:mabarscore/core/constants/app_colors.dart';

class KlasemenView extends StatelessWidget {
  final Map<String, dynamic> klasemenData;
  final String batchId; // Diubah ke String agar konsisten

  const KlasemenView({
    super.key,
    required this.klasemenData,
    required this.batchId,
  });

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
            image: AssetImage('assets/images/bgbraket.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Klasemen Round $batchId",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: klasemenData.length,
                  itemBuilder: (context, index) {
                    String arenaKey = klasemenData.keys.elementAt(index);
                    // Data sekarang adalah Map ID -> {nickname, status}
                    Map<String, dynamic> playersInArena =
                        klasemenData[arenaKey];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fivehero ${arenaKey.replaceAll('_', ' ')}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildArenaCard(playersInArena),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArenaCard(Map<String, dynamic> players) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(86, 13, 92, 83),
            Color.fromARGB(133, 3, 27, 25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(players.length, (index) {
          String playerId = players.keys.elementAt(index);
          var playerData = players[playerId];

          String nickname = playerData['nickname'] ?? "Unknown";
          String status = playerData['status'] ?? "waiting";

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white24,
                  backgroundImage: playerData['avatar_url'] != null
                      ? NetworkImage(playerData['avatar_url'])
                      : null,
                  child: playerData['avatar_url'] == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                // 🔥 PERBAIKAN: Berikan fleksibilitas pada nickname
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis, // Agar tidak overflow
                      ),
                      Text(
                        playerData['rank'] ?? "ID Tidak Diketahui",
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 255, 8),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis, // Agar tidak overflow
                      ),
                    ],
                  ),
                ),
                // 🔥 PERBAIKAN: Berikan ruang untuk status agar tidak berantakan
                Expanded(
                  flex: 2,
                  child: Text(
                    status,
                    textAlign: TextAlign.right, // Teks rata kanan agar rapi
                    style: TextStyle(
                      color: status.contains('Menang')
                          ? Colors.yellow
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
