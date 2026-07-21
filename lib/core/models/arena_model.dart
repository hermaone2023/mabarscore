class ArenaModel {
  final int arenaId;
  final String arenaName;
  final List<PlayerSlot> players;

  ArenaModel({
    required this.arenaId,
    required this.arenaName,
    required this.players,
  });

  factory ArenaModel.fromJson(Map<String, dynamic> json) {
    var list = json['players'] as List;
    List<PlayerSlot> playerList = list
        .map((i) => PlayerSlot.fromJson(i))
        .toList();

    return ArenaModel(
      arenaId: json['arena_id'],
      arenaName: json['arena_name'],
      players: playerList,
    );
  }
}

class PlayerSlot {
  final int slotNumber;
  final String? name;
  final String? imgUrl;
  final String statusPlayer;

  PlayerSlot({
    required this.slotNumber,
    this.name,
    this.imgUrl,
    required this.statusPlayer,
  });

  factory PlayerSlot.fromJson(Map<String, dynamic> json) {
    return PlayerSlot(
      slotNumber: json['slot_number'],
      name: json['nama_player'],
      imgUrl: json['foto_player'],
      statusPlayer: json['status_player'] ?? 'menunggu',
    );
  }
}
