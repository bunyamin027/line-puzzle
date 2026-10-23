import 'dart:math';
import 'dart:ui';
import '../../models/level_model.dart';
import '../constants/app_constants.dart';
import 'euler_solver.dart';

/// Çizgi Bulmaca — Level Deposu & Seviye Üreticisi
/// 4 zorlukta toplam 1200 seviyenin Euler çizgisi (tek hamlede çizilebilir)
/// kuralına uygun olmasını garanti eder (bkz. test/level_repository_test.dart).
class LevelRepository {
  LevelRepository._();

  /// Belirli bir zorluk ve level numarası için LevelModel döner
  static LevelModel getLevel(int difficulty, int levelId) {
    if (difficulty == 0 && levelId <= _easyHandcrafted.length) {
      return _easyHandcrafted[levelId - 1];
    }
    if (difficulty == 1 && levelId <= _mediumHandcrafted.length) {
      return _mediumHandcrafted[levelId - 1];
    }
    if (difficulty == 2 && levelId <= _hardHandcrafted.length) {
      return _hardHandcrafted[levelId - 1];
    }

    // El yapımı seviye sınırını aşanlar için matematiksel Euler üreticisi
    return _generateProceduralLevel(difficulty, levelId);
  }

  // ──────────────────────────────────────────────────────────
  // 1. KOLAY MOD — El Yapımı İkonik Seviyeler (Euler Garantili)
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _easyHandcrafted = [
    // Seviye 1: Üçgen (3 düğüm, 3 kenar - tüm dereceler 2)
    const LevelModel(
      id: 1,
      name: 'Üçgen',
      nameEn: 'Triangle',
      nodes: [
        Offset(0.5, 0.2),
        Offset(0.2, 0.75),
        Offset(0.8, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
      ],
      difficulty: 0,
      parMoves: 3,
    ),

    // Seviye 2: Kum Saati / Papyon (5 düğüm, 6 kenar - tüm dereceler çift)
    const LevelModel(
      id: 2,
      name: 'Kum Saati',
      nameEn: 'Hourglass',
      nodes: [
        Offset(0.25, 0.25),
        Offset(0.75, 0.25),
        Offset(0.5, 0.5),
        Offset(0.25, 0.75),
        Offset(0.75, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0], // Üst üçgen
        [2, 3], [3, 4], [4, 2], // Alt üçgen
      ],
      difficulty: 0,
      parMoves: 6,
    ),

    // Seviye 3: Kare + Çapraz (4 düğüm, 5 kenar - 2 tek derece)
    const LevelModel(
      id: 3,
      name: 'Kare Çapraz',
      nameEn: 'Crossed Square',
      nodes: [
        Offset(0.25, 0.25),
        Offset(0.75, 0.25),
        Offset(0.75, 0.75),
        Offset(0.25, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 0], [0, 2],
      ],
      difficulty: 0,
      parMoves: 5,
    ),

    // Seviye 4: Kelebek (6 düğüm, 7 kenar - 2 tek derece)
    const LevelModel(
      id: 4,
      name: 'Kelebek',
      nameEn: 'Butterfly',
      nodes: [
        Offset(0.2, 0.25),
        Offset(0.35, 0.5),
        Offset(0.2, 0.75),
        Offset(0.65, 0.5),
        Offset(0.8, 0.25),
        Offset(0.8, 0.75),
      ],
      edges: [
        [0, 1], [1, 2], [2, 0], // Sol kanat
        [1, 3],                 // Gövde köprüsü
        [3, 4], [4, 5], [5, 3], // Sağ kanat
      ],
      difficulty: 0,
      parMoves: 7,
    ),

    // Seviye 5: Klasik Ev (5 düğüm, 8 kenar - 2 tek derece: alt köşeler)
    const LevelModel(
      id: 5,
      name: 'Ev',
      nameEn: 'House',
      nodes: [
        Offset(0.5, 0.15), // Çatı
        Offset(0.2, 0.45), // Sol üst
        Offset(0.8, 0.45), // Sağ üst
        Offset(0.2, 0.8),  // Sol alt
        Offset(0.8, 0.8),  // Sağ alt
      ],
      edges: [
        [0, 1], [0, 2], [1, 2],
        [1, 3], [2, 4], [3, 4],
        [1, 4], [2, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 6: Mektup Zarfı (5 düğüm, 8 kenar)
    const LevelModel(
      id: 6,
      name: 'Mektup Zarfı',
      nameEn: 'Envelope',
      nodes: [
        Offset(0.2, 0.4),  // Sol üst
        Offset(0.8, 0.4),  // Sağ üst
        Offset(0.8, 0.8),  // Sağ alt
        Offset(0.2, 0.8),  // Sol alt
        Offset(0.5, 0.15), // Kapak ucu
      ],
      edges: [
        [0, 4], [4, 1],
        [0, 1], [1, 2], [2, 3], [3, 0],
        [0, 2], [1, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 7: Sevimli Balık (6 düğüm, 8 kenar)
    const LevelModel(
      id: 7,
      name: 'Balık',
      nameEn: 'Fish',
      nodes: [
        Offset(0.15, 0.5),  // Burun
        Offset(0.45, 0.28), // Üst sırt
        Offset(0.45, 0.72), // Karın
        Offset(0.65, 0.5),  // Kuyruk sokumu
        Offset(0.85, 0.3),  // Kuyruk üst
        Offset(0.85, 0.7),  // Kuyruk alt
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
        [1, 3], [3, 2],
        [3, 4], [4, 5], [5, 3],
      ],
      difficulty: 0,
      parMoves: 8,
    ),

    // Seviye 8: Yıldız (5 düğüm, 10 kenar - tüm dereceler 4)
    const LevelModel(
      id: 8,
      name: 'Yıldız',
      nameEn: 'Star',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.82, 0.38),
        Offset(0.7, 0.78),
        Offset(0.3, 0.78),
        Offset(0.18, 0.38),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 0], // Dış halka
        [0, 2], [2, 4], [4, 1], [1, 3], [3, 0], // İç yıldız
      ],
      difficulty: 0,
      parMoves: 10,
    ),

    // Seviye 9: Elmas Kristal — oktahedron izdüşümü (6 düğüm, 12 kenar - tüm dereceler 4)
    const LevelModel(
      id: 9,
      name: 'Kristal Elmas',
      nameEn: 'Crystal Diamond',
      nodes: [
        Offset(0.5, 0.12),  // Tepe 0
        Offset(0.18, 0.5),  // Sol 1
        Offset(0.42, 0.4),  // Arka 2
        Offset(0.82, 0.5),  // Sağ 3
        Offset(0.58, 0.6),  // Ön 4
        Offset(0.5, 0.88),  // Dip 5
      ],
      edges: [
        [0, 1], [0, 2], [0, 3], [0, 4], // Tepe piramidi
        [1, 2], [2, 3], [3, 4], [4, 1], // Orta halka
        [5, 1], [5, 2], [5, 3], [5, 4], // Taban piramidi
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 10: Roket (7 düğüm, 12 kenar)
    const LevelModel(
      id: 10,
      name: 'Uzay Roketi',
      nameEn: 'Space Rocket',
      nodes: [
        Offset(0.5, 0.12), // Burun
        Offset(0.35, 0.35),
        Offset(0.65, 0.35),
        Offset(0.35, 0.68),
        Offset(0.65, 0.68),
        Offset(0.15, 0.85), // Sol kanat
        Offset(0.85, 0.85), // Sağ kanat
      ],
      edges: [
        [0, 1], [1, 2], [2, 0],
        [1, 3], [3, 4], [4, 2],
        [1, 4], [2, 3],
        [3, 5], [5, 4],
        [4, 6], [6, 3],
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 11: Altıgen Yıldız (6 düğüm, 12 kenar - tüm dereceler 4)
    const LevelModel(
      id: 11,
      name: 'Altıgen Yıldız',
      nameEn: 'Hexagram',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.8, 0.32),
        Offset(0.8, 0.68),
        Offset(0.5, 0.85),
        Offset(0.2, 0.68),
        Offset(0.2, 0.32),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0], // Dış altıgen
        [0, 2], [2, 4], [4, 0],                         // 1. Üçgen
        [1, 3], [3, 5], [5, 1],                         // 2. Üçgen
      ],
      difficulty: 0,
      parMoves: 12,
    ),

    // Seviye 12: Yelkenli Gemi (6 düğüm, 9 kenar - 2 tek derece)
    const LevelModel(
      id: 12,
      name: 'Yelkenli',
      nameEn: 'Sailboat',
      nodes: [
        Offset(0.5, 0.2),   // Direk tepesi 0
        Offset(0.2, 0.6),   // Sol yelken ucu 1
        Offset(0.5, 0.6),   // Direk tabanı 2
        Offset(0.8, 0.6),   // Sağ yelken ucu 3
        Offset(0.25, 0.82), // Gövde sol alt 4
        Offset(0.75, 0.82), // Gövde sağ alt 5
        Offset(0.3, 0.12),  // Bayrak ucu 6
      ],
      edges: [
        [0, 1], [0, 2], [0, 3], // Direk ve dış yelkenler
        [1, 2], [2, 3],         // Yelken tabanları
        [0, 6], [6, 2],         // Bayrak
        [1, 4], [4, 5], [5, 3], // Gövde
      ],
      difficulty: 0,
      parMoves: 10,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 2. ORTA MOD — El Yapımı Seviyeler
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _mediumHandcrafted = [
    const LevelModel(
      id: 1,
      name: 'Elmas Kafes',
      nameEn: 'Diamond Lattice',
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.2, 0.5),
        Offset(0.8, 0.5),
        Offset(0.5, 0.85),
        Offset(0.5, 0.5),
        Offset(0.18, 0.18),
        Offset(0.82, 0.82),
      ],
      edges: [
        [0, 1], [0, 2], [1, 3], [2, 3],
        [0, 4], [3, 4], [1, 4], [2, 4],
        [0, 5], [5, 1], [2, 6], [6, 3],
      ],
      difficulty: 1,
      parMoves: 12,
    ),
    const LevelModel(
      id: 2,
      name: 'Kale Kulesi',
      nameEn: 'Castle Tower',
      nodes: [
        Offset(0.5, 0.15), // Çatı tepe 0
        Offset(0.3, 0.35), // Sol kule üst 1
        Offset(0.7, 0.35), // Sağ kule üst 2
        Offset(0.3, 0.65), // Sol gövde 3
        Offset(0.7, 0.65), // Sağ gövde 4
        Offset(0.2, 0.85), // Sol taban 5
        Offset(0.8, 0.85), // Sağ taban 6
      ],
      edges: [
        [0, 1], [0, 2], [1, 2],
        [1, 3], [2, 4], [3, 4], [1, 4], [2, 3],
        [3, 5], [5, 6], [6, 4],
      ],
      difficulty: 1,
      parMoves: 11,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 3. ZOR MOD — El Yapımı Seviyeler
  // ──────────────────────────────────────────────────────────

  static final List<LevelModel> _hardHandcrafted = [
    const LevelModel(
      id: 1,
      name: 'Usta Düğümü',
      nameEn: "Master's Knot",
      nodes: [
        Offset(0.5, 0.15),
        Offset(0.8, 0.3),
        Offset(0.85, 0.65),
        Offset(0.65, 0.85),
        Offset(0.35, 0.85),
        Offset(0.15, 0.65),
        Offset(0.2, 0.3),
        Offset(0.5, 0.5),
      ],
      edges: [
        [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0],
        [0, 7], [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
        [0, 3], [1, 4], [2, 5],
      ],
      difficulty: 2,
      parMoves: 17,
    ),
  ];

  // ──────────────────────────────────────────────────────────
  // 4. PROSEDÜREL SEVİYE ÜRETİCİSİ
  // Düzen (ızgara, üçgen kafes, çift halka, merkezli çember) seçilir; aday
  // kenarlardan kenar-ayrık döngüler birleştirilerek bağlı ve tüm dereceleri
  // çift bir graf kurulur (Euler devresi garantili). İsteğe bağlı olarak tek
  // bir kenar çıkarılır: çift dereceli bağlı grafta köprü olmadığından graf
  // bağlı kalır ve tam 2 tek dereceli düğüm oluşur (Euler yolu).
  // Aynı (zorluk, seviye) için her zaman aynı bulmaca üretilir (seed'li RNG).
  // ──────────────────────────────────────────────────────────

  static final Map<int, LevelModel> _cache = {};

  /// Bir kenarın, uç noktası olmayan bir düğüme yaklaşabileceği en az mesafe
  /// (normalize koordinat). Oyuncunun hangi kenarı çizdiğini net görmesi için.
  static const double minEdgeClearance = 0.045;

  static LevelModel _generateProceduralLevel(int difficulty, int levelId) {
    final key = difficulty * 100000 + levelId;
    final cached = _cache[key];
    if (cached != null) return cached;

    final rng = Random(levelId * 31337 + difficulty * 7919 + 17);
    final total = AppConstants.levelCountFor(difficulty);
    final t = total > 0 ? (levelId / total).clamp(0.0, 1.0) : 0.0;

    final (lo, hi) = switch (difficulty) {
      0 => (5, 12),
      1 => (10, 18),
      2 => (15, 26),
      _ => (22, 36),
    };
    final target = lo + ((hi - lo) * t).round() + rng.nextInt(3);

    List<List<int>>? edges;
    List<Offset>? nodes;
    for (int attempt = 0; attempt < 24 && edges == null; attempt++) {
      final layout = _pickLayout(rng, difficulty, target);
      final built = _buildEulerianGraph(rng, layout, target);
      if (built == null) continue;

      // Kolay modda daha çok devre (her yerden başlanabilir), üst modlarda yol
      final pathChance = difficulty == 0 ? 0.4 : 0.7;
      if (rng.nextDouble() < pathChance && built.length > 3) {
        built.removeAt(rng.nextInt(built.length));
      }

      final compact = _compact(layout.points, built);
      if (compact.$1.length < 3) continue;
      if (EulerSolver.findSolution(compact.$1.length, compact.$2) == null) continue;
      nodes = compact.$1;
      edges = compact.$2;
    }

    // Güvenlik ağı: hiçbir deneme tutmazsa kesin geçerli basit çember
    if (edges == null || nodes == null) {
      final n = 4 + difficulty;
      nodes = _fitToCanvas(_ringPoints(n, 1.0));
      edges = [for (int i = 0; i < n; i++) [i, (i + 1) % n]];
    }

    final namePair = _names[(levelId * 7 + difficulty * 5) % _names.length];
    final level = LevelModel(
      id: levelId,
      name: '${namePair.$1} #$levelId',
      nameEn: '${namePair.$2} #$levelId',
      nodes: nodes,
      edges: edges,
      difficulty: difficulty,
      parMoves: edges.length,
    );
    _cache[key] = level;
    return level;
  }

  static const List<(String, String)> _names = [
    ('Göktaşı', 'Meteor'), ('Kalkan', 'Shield'), ('Pusula', 'Compass'),
    ('Fener', 'Lighthouse'), ('Rüzgar Gülü', 'Wind Rose'), ('Taç', 'Crown'),
    ('Girdap', 'Vortex'), ('Piramit', 'Pyramid'), ('Köprü', 'Bridge'),
    ('Akrep', 'Scorpion'), ('Kartal', 'Eagle'), ('Uçurtma', 'Kite'),
    ('Labirent', 'Labyrinth'), ('Sonsuzluk', 'Infinity'), ('Geometri', 'Geometry'),
    ('Kristal', 'Crystal'), ('Takımyıldız', 'Constellation'), ('Petek', 'Honeycomb'),
    ('Ağ', 'Web'), ('Mozaik', 'Mosaic'), ('Prizma', 'Prism'),
    ('Nebula', 'Nebula'), ('Kuyrukluyıldız', 'Comet'), ('Yörünge', 'Orbit'),
    ('Kar Tanesi', 'Snowflake'), ('Kale', 'Fortress'), ('Lotus', 'Lotus'),
    ('Atom', 'Atom'), ('Galaksi', 'Galaxy'), ('Kubbe', 'Dome'),
  ];

  // ─── Düzenler ──────────────────────────────────────────────

  static _Layout _pickLayout(Random rng, int difficulty, int target) {
    final options = <_Layout Function()>[
      ...switch (difficulty) {
        0 => [
            () => _ring(4 + rng.nextInt(3), maxStep: 2, rng: rng),
            () => _ring(4 + rng.nextInt(3), maxStep: 1, center: true, rng: rng),
            () => _grid(2, 3),
            () => _grid(3, 3),
          ],
        1 => [
            () => _ring(5 + rng.nextInt(3), maxStep: 2, center: true, rng: rng),
            () => _grid(3, 3),
            () => _grid(3, 4),
            () => _triangular(3, 3),
            () => _doubleRing(4, center: false, rng: rng),
          ],
        2 => [
            () => _grid(3, 4),
            () => _grid(4, 4),
            () => _triangular(4, 4),
            () => _doubleRing(5, center: rng.nextBool(), rng: rng),
            () => _ring(8, maxStep: 2, center: true, rng: rng),
          ],
        _ => [
            () => _grid(4, 5),
            () => _grid(5, 5),
            () => _triangular(5, 4),
            () => _doubleRing(6 + rng.nextInt(2), center: true, rng: rng),
          ],
      },
    ];

    // Hedef kenar sayısını rahat karşılayabilecek bir düzen seç
    for (int i = 0; i < 8; i++) {
      final layout = options[rng.nextInt(options.length)]();
      if (layout.candidates.length >= (target * 1.4).ceil()) return layout;
    }
    return options.last();
  }

  static List<Offset> _ringPoints(int n, double r, {double rotation = -pi / 2}) => [
        for (int i = 0; i < n; i++)
          Offset(r * cos(rotation + 2 * pi * i / n), r * sin(rotation + 2 * pi * i / n)),
      ];

  static _Layout _ring(int n, {required int maxStep, bool center = false, required Random rng}) {
    final rotation = -pi / 2 + (rng.nextBool() ? pi / n : 0);
    final points = _ringPoints(n, 1.0, rotation: rotation);
    final pairs = <List<int>>[];
    for (int i = 0; i < n; i++) {
      for (int step = 1; step <= maxStep; step++) {
        final j = (i + step) % n;
        if (step * 2 == n && i >= j) continue; // karşıt çiftler bir kez
        pairs.add([i, j]);
      }
    }
    if (center) {
      points.add(Offset.zero);
      for (int i = 0; i < n; i++) {
        pairs.add([i, n]);
      }
    }
    return _Layout.filtered(points, pairs);
  }

  static _Layout _grid(int rows, int cols) {
    final points = <Offset>[
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) Offset(c.toDouble(), r.toDouble()),
    ];
    final pairs = <List<int>>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final i = r * cols + c;
        if (c + 1 < cols) pairs.add([i, i + 1]);
        if (r + 1 < rows) pairs.add([i, i + cols]);
        if (r + 1 < rows && c + 1 < cols) pairs.add([i, i + cols + 1]);
        if (r + 1 < rows && c > 0) pairs.add([i, i + cols - 1]);
      }
    }
    return _Layout.filtered(points, pairs);
  }

  static _Layout _triangular(int rows, int cols) {
    final h = sqrt(3) / 2;
    final points = <Offset>[
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) Offset(c + (r.isOdd ? 0.5 : 0.0), r * h),
    ];
    final pairs = <List<int>>[];
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        if (((points[i] - points[j]).distance - 1.0).abs() < 0.01) pairs.add([i, j]);
      }
    }
    return _Layout.filtered(points, pairs);
  }

  static _Layout _doubleRing(int n, {required bool center, required Random rng}) {
    final rotation = -pi / 2 + rng.nextDouble() * pi / n;
    final inner = _ringPoints(n, 0.48, rotation: rotation);
    final outer = _ringPoints(n, 1.0, rotation: rotation + pi / n);
    final points = [...inner, ...outer];
    final pairs = <List<int>>[];
    for (int i = 0; i < n; i++) {
      pairs.add([i, (i + 1) % n]);                 // iç halka
      pairs.add([n + i, n + (i + 1) % n]);         // dış halka
      pairs.add([i, n + i]);                       // iç → dış
      pairs.add([i, n + (i - 1 + n) % n]);         // iç → önceki dış
    }
    if (center) {
      points.add(Offset.zero);
      for (int i = 0; i < n; i++) {
        pairs.add([i, 2 * n]);
      }
    }
    return _Layout.filtered(points, pairs);
  }

  // ─── Graf Kurulumu ─────────────────────────────────────────

  /// Kenar-ayrık döngüleri birleştirerek bağlı, tüm dereceleri çift bir graf kurar.
  static List<List<int>>? _buildEulerianGraph(Random rng, _Layout layout, int target) {
    final cand = layout.candidates;
    final n = layout.points.length;
    final incident = List.generate(n, (_) => <int>[]);
    for (int e = 0; e < cand.length; e++) {
      incident[cand[e][0]].add(e);
      incident[cand[e][1]].add(e);
    }
    int other(int e, int v) => cand[e][0] == v ? cand[e][1] : cand[e][0];

    final used = <int>{};
    final touched = <int>{};

    for (int guard = 0; guard < 300 && used.length < target; guard++) {
      final pool = touched.isEmpty ? List<int>.generate(n, (i) => i) : touched.toList();
      final u = pool[rng.nextInt(pool.length)];
      final free = incident[u].where((e) => !used.contains(e)).toList();
      if (free.isEmpty) continue;
      final first = free[rng.nextInt(free.length)];
      final v = other(first, u);

      // v'den u'ya, kullanılmamış kenarlarla rastgele sıralı BFS → basit döngü
      final prevEdge = <int, int>{v: -1};
      final queue = <int>[v];
      for (int qi = 0; qi < queue.length && !prevEdge.containsKey(u); qi++) {
        final x = queue[qi];
        final edgesOut = incident[x].toList()..shuffle(rng);
        for (final e in edgesOut) {
          if (e == first || used.contains(e)) continue;
          final y = other(e, x);
          if (prevEdge.containsKey(y)) continue;
          prevEdge[y] = e;
          queue.add(y);
        }
      }
      if (!prevEdge.containsKey(u)) continue;

      final cycle = <int>[first];
      for (int x = u; x != v; x = other(prevEdge[x]!, x)) {
        cycle.add(prevEdge[x]!);
      }
      if (used.length + cycle.length > target + 3) continue;

      for (final e in cycle) {
        used.add(e);
        touched
          ..add(cand[e][0])
          ..add(cand[e][1]);
      }
    }

    if (used.length < max(3, (target * 0.75).floor())) return null;
    return [for (final e in used) List<int>.from(cand[e])];
  }

  /// Kullanılmayan düğümleri atar, indeksleri sıkıştırır ve tuvale sığdırır.
  static (List<Offset>, List<List<int>>) _compact(List<Offset> points, List<List<int>> edges) {
    final remap = <int, int>{};
    final kept = <Offset>[];
    for (final e in edges) {
      for (final v in e) {
        remap.putIfAbsent(v, () {
          kept.add(points[v]);
          return kept.length - 1;
        });
      }
    }
    return (
      _fitToCanvas(kept),
      [for (final e in edges) [remap[e[0]]!, remap[e[1]]!]],
    );
  }

  /// Noktaları en-boy oranını koruyarak [0.1, 0.9] karesine ortalar.
  static List<Offset> _fitToCanvas(List<Offset> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
    final extent = max(maxX - minX, maxY - minY);
    final scale = extent > 0 ? 0.8 / extent : 1.0;
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    return [
      for (final p in pts) Offset(0.5 + (p.dx - cx) * scale, 0.5 + (p.dy - cy) * scale),
    ];
  }

  /// Nokta ile doğru parçası arasındaki en kısa mesafe
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }
}

/// Aday düğüm noktaları ve aralarında çizilebilecek kenarlar
class _Layout {
  final List<Offset> points;
  final List<List<int>> candidates;

  const _Layout(this.points, this.candidates);

  /// Uç noktası olmayan bir düğüme fazla yaklaşan kenarları eler.
  /// Mesafe kontrolü, düzen tuvale sığdırılmış ölçekte yapılır.
  factory _Layout.filtered(List<Offset> points, List<List<int>> pairs) {
    final fitted = LevelRepository._fitToCanvas(points);
    final ok = <List<int>>[];
    for (final pair in pairs) {
      final a = fitted[pair[0]], b = fitted[pair[1]];
      var clear = true;
      for (int k = 0; k < fitted.length && clear; k++) {
        if (k == pair[0] || k == pair[1]) continue;
        if (LevelRepository.distanceToSegment(fitted[k], a, b) <
            LevelRepository.minEdgeClearance) {
          clear = false;
        }
      }
      if (clear) ok.add(pair);
    }
    return _Layout(points, ok);
  }
}
