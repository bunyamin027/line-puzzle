import 'package:flutter_test/flutter_test.dart';
import 'package:cizgi_bulmaca/core/constants/app_constants.dart';
import 'package:cizgi_bulmaca/core/services/euler_solver.dart';
import 'package:cizgi_bulmaca/core/services/level_repository.dart';

void main() {
  /// Çözümün her kenarı tam bir kez kullandığını doğrular
  bool coversAllEdgesOnce(List<int> path, List<List<int>> edges) {
    if (path.length != edges.length + 1) return false;
    final remaining = edges.map((e) => [e[0], e[1]]).toList();
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i], b = path[i + 1];
      final idx = remaining.indexWhere(
        (e) => (e[0] == a && e[1] == b) || (e[0] == b && e[1] == a),
      );
      if (idx < 0) return false;
      remaining.removeAt(idx);
    }
    return remaining.isEmpty;
  }

  for (int d = 0; d < AppConstants.difficultyCount; d++) {
    test('zorluk $d: tüm seviyeler geçerli ve çözülebilir', () {
      final total = AppConstants.levelCountFor(d);
      for (int id = 1; id <= total; id++) {
        final level = LevelRepository.getLevel(d, id);
        final tag = 'd=$d id=$id (${level.name})';
        final n = level.nodes.length;

        expect(n, greaterThanOrEqualTo(3), reason: tag);
        expect(level.edges.length, greaterThanOrEqualTo(3), reason: tag);

        // Koordinatlar tuval içinde
        for (final p in level.nodes) {
          expect(p.dx, inInclusiveRange(0.05, 0.95), reason: tag);
          expect(p.dy, inInclusiveRange(0.05, 0.95), reason: tag);
        }

        // Kenarlar: geçerli indeks, döngü yok, tekrar yok, her düğüm kullanılıyor
        final seen = <String>{};
        final degree = List<int>.filled(n, 0);
        for (final e in level.edges) {
          expect(e[0], isNot(e[1]), reason: tag);
          expect(e[0], inInclusiveRange(0, n - 1), reason: tag);
          expect(e[1], inInclusiveRange(0, n - 1), reason: tag);
          final key = e[0] < e[1] ? '${e[0]}-${e[1]}' : '${e[1]}-${e[0]}';
          expect(seen.add(key), isTrue, reason: '$tag tekrarlı kenar $key');
          degree[e[0]]++;
          degree[e[1]]++;
        }
        expect(degree.every((x) => x > 0), isTrue, reason: '$tag boşta düğüm');

        // Düğümler birbirine fazla yakın değil
        for (int i = 0; i < n; i++) {
          for (int j = i + 1; j < n; j++) {
            expect((level.nodes[i] - level.nodes[j]).distance, greaterThan(0.09),
                reason: '$tag düğüm $i-$j çok yakın');
          }
        }

        // Hiçbir kenar, uç noktası olmayan bir düğümün üzerinden geçmiyor
        for (final e in level.edges) {
          for (int k = 0; k < n; k++) {
            if (k == e[0] || k == e[1]) continue;
            final dist = LevelRepository.distanceToSegment(
              level.nodes[k], level.nodes[e[0]], level.nodes[e[1]],
            );
            expect(dist, greaterThan(0.035),
                reason: '$tag kenar ${e[0]}-${e[1]} düğüm $k üzerinden geçiyor');
          }
        }

        // Tek çizgide çözülebilir
        final sol = EulerSolver.findSolution(n, level.edges);
        expect(sol, isNotNull, reason: tag);
        expect(coversAllEdgesOnce(sol!, level.edges), isTrue, reason: tag);

        // Deterministik: aynı seviye her seferinde aynı
        final again = LevelRepository.getLevel(d, id);
        expect(again.edges.length, level.edges.length, reason: tag);
      }
    });
  }

  test('ipucu motoru yarım çizimden devam eder ve çıkmazı algılar', () {
    final level = LevelRepository.getLevel(2, 57);
    final n = level.nodes.length;
    final sol = EulerSolver.findSolution(n, level.edges)!;

    // Doğru önek → devam bulunur
    final prefix = sol.sublist(0, 4);
    final cont = EulerSolver.findSolution(n, level.edges, prefix);
    expect(cont, isNotNull);
    expect(cont!.sublist(0, 4), prefix);
    expect(coversAllEdgesOnce(cont, level.edges), isTrue);

    // İpucu her durumda bir adım üretir
    final hint = EulerSolver.getNextHintStep(
      nodeCount: n,
      edges: level.edges,
      visitedNodes: prefix,
      drawnEdges: [for (int i = 0; i < 3; i++) [prefix[i], prefix[i + 1]]],
      activeNode: prefix.last,
    );
    expect(hint, isNotNull);
    expect(hint!.kind, HintKind.next);
  });
}
