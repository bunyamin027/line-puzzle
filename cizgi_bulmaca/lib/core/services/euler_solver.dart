import 'dart:math';

/// İpucunun hangi durumda üretildiği (arayüzde yerelleştirilmiş mesaj seçimi için)
enum HintKind { start, next, rollback, wrongStart }

/// İpucu adım sonucu ve durum analizi
class HintStepResult {
  final int fromNode;
  final int toNode;
  final List<int> rollbackVisitedNodes;
  final List<List<int>> rollbackDrawnEdges;
  final bool didRollback;
  final int rollbackCount;
  final bool isWrongStart;
  final List<int> validStartNodes;
  final List<int> fullSolution;        // 0'dan tam Euler yolu düğüm sırası
  final List<List<int>> upcomingSteps; // Sonraki 1-3 önerilen kenar
  final HintKind kind;

  const HintStepResult({
    required this.fromNode,
    required this.toNode,
    required this.rollbackVisitedNodes,
    required this.rollbackDrawnEdges,
    required this.didRollback,
    this.rollbackCount = 0,
    this.isWrongStart = false,
    this.validStartNodes = const [],
    this.fullSolution = const [],
    this.upcomingSteps = const [],
    required this.kind,
  });

  /// Kullanıcının yaptığı hamle sayısı yüksek ve büyük bir geri alma gerekiyor mu?
  bool get isMajorDeadlock => didRollback && (isWrongStart || rollbackCount >= 3);
}

/// Çizgi Bulmaca — Euler Yolu Çözücüsü & Akıllı İpucu Motoru
/// Graf üzerindeki tek çizgi yolunu (Eulerian path/trail) bulur
/// ve oyuncuya en yardımcı, yıkıcı olmayan doğru hamleyi üretir.
class EulerSolver {
  EulerSolver._();

  /// Grafın geçerli Euler başlangıç düğümlerini döner.
  /// Grafın 2 tek dereceli düğümü varsa SADECE o 2 düğümden başlanabilir.
  /// Tüm düğümler çift dereceli ise herhangi bir düğümden başlanabilir.
  static List<int> getValidStartNodes(int nodeCount, List<List<int>> edges) {
    final degrees = List<int>.filled(nodeCount, 0);
    for (final e in edges) {
      degrees[e[0]]++;
      degrees[e[1]]++;
    }
    final oddNodes = <int>[];
    for (int i = 0; i < nodeCount; i++) {
      if (degrees[i] % 2 != 0) {
        oddNodes.add(i);
      }
    }
    if (oddNodes.length == 2) {
      return oddNodes;
    }
    return List.generate(nodeCount, (i) => i);
  }

  /// Verilen düğüm ve kenar listesi için tam bir Euler yolu bulur.
  /// [currentPath] verilirse o yoldan devam eden bir çözüm arar.
  /// Çözüm düğüm indekslerinin sırasıdır: [v0, v1, v2, ..., vm].
  ///
  /// Hierholzer algoritması kullanılır: O(V + E). Önceki geri izlemeli DFS
  /// büyük graflarda üstel süreye çıkıp UI'ı kilitleyebiliyordu.
  static List<int>? findSolution(
    int nodeCount,
    List<List<int>> edges, [
    List<int>? currentPath,
  ]) {
    final adj = List.generate(nodeCount, (_) => <_EdgeNeighbor>[]);
    for (int idx = 0; idx < edges.length; idx++) {
      final u = edges[idx][0];
      final v = edges[idx][1];
      adj[u].add(_EdgeNeighbor(v, idx));
      adj[v].add(_EdgeNeighbor(u, idx));
    }

    // Henüz başlanmamışsa: tek dereceli düğümlerden (varsa) veya ilk düğümden başla
    if (currentPath == null || currentPath.isEmpty) {
      final odd = _oddNodes(nodeCount, adj, const <int>{});
      if (odd.isNotEmpty && odd.length != 2) return null;
      final start = odd.isNotEmpty
          ? odd.first
          : adj.indexWhere((n) => n.isNotEmpty);
      if (start < 0) return null;
      final trail = _trailFrom(start, adj, <int>{}, edges.length);
      return trail;
    }

    // Başlanmışsa: currentPath içindeki kenarları doğrula
    final usedEdges = <int>{};
    for (int k = 0; k < currentPath.length - 1; k++) {
      final u = currentPath[k];
      final v = currentPath[k + 1];
      int foundIndex = -1;
      for (int i = 0; i < edges.length; i++) {
        final eu = edges[i][0];
        final ev = edges[i][1];
        if (((eu == u && ev == v) || (eu == v && ev == u)) &&
            !usedEdges.contains(i)) {
          foundIndex = i;
          break;
        }
      }
      if (foundIndex == -1) {
        return null; // Geçersiz çizim yolu
      }
      usedEdges.add(foundIndex);
    }

    final cur = currentPath.last;
    if (usedEdges.length == edges.length) return List<int>.from(currentPath);

    // Kalan graf, mevcut düğümden başlayan bir Euler yoluna sahip olmalı:
    // tek dereceli düğüm yok ya da tam 2 tane ve biri mevcut düğüm.
    final odd = _oddNodes(nodeCount, adj, usedEdges);
    if (odd.isNotEmpty && !(odd.length == 2 && odd.contains(cur))) return null;

    final rest = _trailFrom(cur, adj, usedEdges, edges.length - usedEdges.length);
    if (rest == null) return null;
    return [...currentPath, ...rest.skip(1)];
  }

  static List<int> _oddNodes(
    int nodeCount,
    List<List<_EdgeNeighbor>> adj,
    Set<int> usedEdges,
  ) {
    final odd = <int>[];
    for (int i = 0; i < nodeCount; i++) {
      final deg = adj[i].where((n) => !usedEdges.contains(n.edgeIndex)).length;
      if (deg.isOdd) odd.add(i);
    }
    return odd;
  }

  /// [start]'tan kullanılmamış kenarlar üzerinde Hierholzer turu.
  /// Kalan kenarların hepsi tek bir yolda toplanamıyorsa (bağlantısız) null döner.
  static List<int>? _trailFrom(
    int start,
    List<List<_EdgeNeighbor>> adj,
    Set<int> usedEdges,
    int remainingCount,
  ) {
    final used = Set<int>.from(usedEdges);
    final cursor = List<int>.filled(adj.length, 0);
    final stack = <int>[start];
    final trail = <int>[];

    while (stack.isNotEmpty) {
      final v = stack.last;
      final list = adj[v];
      while (cursor[v] < list.length && used.contains(list[cursor[v]].edgeIndex)) {
        cursor[v]++;
      }
      if (cursor[v] == list.length) {
        trail.add(stack.removeLast());
      } else {
        final next = list[cursor[v]];
        used.add(next.edgeIndex);
        stack.add(next.targetNode);
      }
    }

    if (trail.length != remainingCount + 1) return null;
    return trail.reversed.toList();
  }

  /// Oyuncunun mevcut tahta durumuna göre bir sonraki akıllı ipucu adımını üretir.
  static HintStepResult? getNextHintStep({
    required int nodeCount,
    required List<List<int>> edges,
    required List<int> visitedNodes,
    required List<List<int>> drawnEdges,
    required int? activeNode,
  }) {
    final validStarts = getValidStartNodes(nodeCount, edges);
    final fullSol = findSolution(nodeCount, edges) ?? <int>[];

    // 1) Oyuncu henüz hiç başlamadıysa
    if (visitedNodes.isEmpty || activeNode == null) {
      if (fullSol.length < 2) return null;

      final upcoming = <List<int>>[];
      for (int i = 0; i < min(3, fullSol.length - 1); i++) {
        upcoming.add([fullSol[i], fullSol[i + 1]]);
      }

      return HintStepResult(
        fromNode: fullSol[0],
        toNode: fullSol[1],
        rollbackVisitedNodes: [fullSol[0]],
        rollbackDrawnEdges: [],
        didRollback: false,
        validStartNodes: validStarts,
        fullSolution: fullSol,
        upcomingSteps: upcoming,
        kind: HintKind.start,
      );
    }

    // 2) Oyuncu mevcut yolundan devam edebiliyor mu?
    final continuation = findSolution(nodeCount, edges, visitedNodes);
    if (continuation != null && continuation.length > visitedNodes.length) {
      final nextNode = continuation[visitedNodes.length];
      final upcoming = <List<int>>[];
      for (int i = visitedNodes.length - 1;
          i < min(visitedNodes.length + 2, continuation.length - 1);
          i++) {
        upcoming.add([continuation[i], continuation[i + 1]]);
      }

      return HintStepResult(
        fromNode: activeNode,
        toNode: nextNode,
        rollbackVisitedNodes: visitedNodes,
        rollbackDrawnEdges: drawnEdges,
        didRollback: false,
        rollbackCount: 0,
        validStartNodes: validStarts,
        fullSolution: continuation,
        upcomingSteps: upcoming,
        kind: HintKind.next,
      );
    }

    // 3) Çıkmaz sokak! Başlangıç noktası geçerli mi kontrol et
    final isWrongStart = !validStarts.contains(visitedNodes.first);

    if (!isWrongStart) {
      // Başlangıç doğru ama arada bir ayrımda yanlış yola girilmiş:
      // En uzun geçerli ön-eki bul
      for (int k = visitedNodes.length - 1; k >= 1; k--) {
        final prefix = visitedNodes.sublist(0, k);
        final candidateSol = findSolution(nodeCount, edges, prefix);
        if (candidateSol != null && candidateSol.length > k) {
          final prefixDrawn = drawnEdges.sublist(0, min(k - 1, drawnEdges.length));
          final nextNode = candidateSol[k];
          final rollbackCount = visitedNodes.length - k;

          final upcoming = <List<int>>[];
          for (int i = k - 1; i < min(k + 2, candidateSol.length - 1); i++) {
            upcoming.add([candidateSol[i], candidateSol[i + 1]]);
          }

          return HintStepResult(
            fromNode: prefix.last,
            toNode: nextNode,
            rollbackVisitedNodes: prefix,
            rollbackDrawnEdges: prefixDrawn,
            didRollback: true,
            rollbackCount: rollbackCount,
            isWrongStart: false,
            validStartNodes: validStarts,
            fullSolution: candidateSol,
            upcomingSteps: upcoming,
            kind: HintKind.rollback,
          );
        }
      }
    }

    // 4) Başlangıç noktası hatalı (veya hiçbir ön-ek çözülemiyor)
    if (fullSol.length >= 2) {
      final upcoming = <List<int>>[];
      for (int i = 0; i < min(3, fullSol.length - 1); i++) {
        upcoming.add([fullSol[i], fullSol[i + 1]]);
      }

      return HintStepResult(
        fromNode: fullSol[0],
        toNode: fullSol[1],
        rollbackVisitedNodes: [fullSol[0]],
        rollbackDrawnEdges: [],
        didRollback: true,
        rollbackCount: visitedNodes.length,
        isWrongStart: true,
        validStartNodes: validStarts,
        fullSolution: fullSol,
        upcomingSteps: upcoming,
        kind: HintKind.wrongStart,
      );
    }

    return null;
  }
}

class _EdgeNeighbor {
  final int targetNode;
  final int edgeIndex;

  const _EdgeNeighbor(this.targetNode, this.edgeIndex);
}
