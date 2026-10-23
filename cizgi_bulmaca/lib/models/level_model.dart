import 'dart:ui';

/// Çizgi Bulmaca — Level Model
/// Her bir bulmaca level'ını temsil eder.
class LevelModel {
  final int id;
  final String name;                 // Türkçe isim
  final String? nameEn;              // İngilizce isim (yoksa Türkçe kullanılır)
  final List<Offset> nodes;         // Düğüm noktaları
  final List<List<int>> edges;      // Kenar bağlantıları [fromIndex, toIndex]
  final List<int>? solutionPath;    // Çözüm yolu (index sırası)
  final int difficulty;              // 0=kolay, 1=orta, 2=zor
  final int parMoves;               // Minimum hamle sayısı (yıldız hesabı)

  const LevelModel({
    required this.id,
    required this.name,
    this.nameEn,
    required this.nodes,
    required this.edges,
    this.solutionPath,
    required this.difficulty,
    required this.parMoves,
  });

  String localizedName(String locale) =>
      locale == 'en' ? (nameEn ?? name) : name;

  /// JSON'dan level oluştur
  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Level ${json['id']}',
      nameEn: json['nameEn'] as String?,
      nodes: (json['nodes'] as List).map((n) {
        final coords = n as List;
        return Offset(
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        );
      }).toList(),
      edges: (json['edges'] as List).map((e) {
        final edge = e as List;
        return [edge[0] as int, edge[1] as int];
      }).toList(),
      solutionPath: json['solution'] != null
          ? (json['solution'] as List).cast<int>()
          : null,
      difficulty: json['difficulty'] as int? ?? 0,
      parMoves: json['parMoves'] as int? ?? 0,
    );
  }

  /// Level'ı JSON'a dönüştür
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'nodes': nodes.map((n) => [n.dx, n.dy]).toList(),
        'edges': edges,
        'solution': solutionPath,
        'difficulty': difficulty,
        'parMoves': parMoves,
      };
}
