import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/game_provider.dart';
import '../../core/services/settings_provider.dart';
import '../../core/services/achievement_provider.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/level_repository.dart';
import '../../core/services/euler_solver.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../models/difficulty.dart';
import '../../models/level_model.dart';
import 'game_painter.dart';
import 'level_complete_dialog.dart';

/// Çizgi Bulmaca — Oynanış Ekranı
/// Parmağını kaldırmadan düğümler arasında çizgi çiz.
class GameScreen extends StatefulWidget {
  final int levelId;
  final int difficulty;

  const GameScreen({super.key, required this.levelId, this.difficulty = 0});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Level verileri
  late LevelModel _currentLevel;
  late List<Offset> _nodes;       // Normalize edilmiş koordinatlar (0-1)
  late List<List<int>> _edges;    // Kenar bağlantıları
  late Difficulty _difficulty;
  double _minNodeDistance = 1.0;  // En yakın iki düğüm arası (normalize)

  // Oyun durumu
  final List<int> _visitedNodes = [];
  final List<List<int>> _drawnEdges = [];
  final List<double> _drawnTimes = []; // _drawnEdges ile paralel: çizilme anı (sn)
  int? _activeNode;
  int _moveCount = 0;
  bool _isCompleted = false;
  bool _isDragging = false;
  Offset? _currentDragPos;        // Sürükleme sırasındaki parmak pozisyonu
  List<int>? _lastHintEdge;       // İpucu ile çizilen son kenar
  List<int> _validStartNodes = []; // Seviyenin geçerli başlangıç düğümleri
  List<List<int>>? _ghostEdges;   // Kılavuz / önizleme adımları
  Timer? _ghostTimer;             // Kılavuz otomatik kapanma zamanlayıcısı

  // Yıldız hesabı için oturum istatistikleri
  int _hintsUsed = 0;
  int _mistakes = 0; // geri alma + dolu tahtayı sıfırlama

  // Efekt zamanlaması
  final Stopwatch _clock = Stopwatch()..start();
  final List<GameEffect> _effects = [];
  double? _completedAt;
  double _lastInvalidAt = -10;
  int? _invalidHoverNode;

  // Süre ölçümü
  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedMs = 0;
  final Stream<void> _secondTicks = Stream.periodic(const Duration(seconds: 1));

  // Mükemmel seri takibi
  static int _consecutivePerfects = 0;

  // Çizim alanı boyutları (LayoutBuilder'dan)
  Size _canvasSize = Size.zero;

  // Animasyon
  late final AnimationController _pulseController;
  late final AnimationController _introController;

  double get _now => _clock.elapsedMicroseconds / 1e6;

  /// Başlangıç halkaları yalnızca Kolay/Orta modda gösterilir;
  /// üst modlarda doğru başlangıcı bulmak bulmacanın parçası.
  bool get _showStartHints => widget.difficulty <= 1;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _stopwatch.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
        _syncSettings();
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId != widget.levelId || oldWidget.difficulty != widget.difficulty) {
      _initLevel();
      _restartFresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GameProvider>().setLastPlayed(widget.difficulty, widget.levelId);
        }
      });
    }
  }

  @override
  void dispose() {
    _ghostTimer?.cancel();
    _pulseController.dispose();
    _introController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _initLevel() {
    _difficulty = Difficulty.fromIndex(widget.difficulty);
    _currentLevel = LevelRepository.getLevel(widget.difficulty, widget.levelId);
    _nodes = _currentLevel.nodes;
    _edges = _currentLevel.edges;
    _validStartNodes = EulerSolver.getValidStartNodes(_nodes.length, _edges);
    _ghostEdges = null;
    _ghostTimer?.cancel();

    _minNodeDistance = 1.0;
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        _minNodeDistance = min(_minNodeDistance, (_nodes[i] - _nodes[j]).distance);
      }
    }
  }

  /// Ses ve haptic ayarlarını provider'dan senkronize et
  void _syncSettings() {
    final settings = context.read<SettingsProvider>();
    HapticService.setEnabled(settings.hapticEnabled);
    SoundService.instance.setEnabled(settings.soundEnabled);
  }

  BoardGeometry get _geometry => BoardGeometry(_canvasSize);

  /// Yoğun bulmacalarda düğümler sıkışınca dokunma alanları çakışmasın
  double get _nodeHitRadius => min(36.0, _minNodeDistance * _geometry.side * 0.48);

  double get _nodeRadius => (_minNodeDistance * _geometry.side * 0.26).clamp(9.0, 14.0);

  /// Verilen piksel pozisyonuna en yakın düğümü bul (hit radius içinde)
  int? _findNodeAt(Offset position) {
    final geo = _geometry;
    int? best;
    var bestDistance = _nodeHitRadius;
    for (int i = 0; i < _nodes.length; i++) {
      final distance = (position - geo.toPixel(_nodes[i])).distance;
      if (distance <= bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  /// Geçen süreyi formatla (MM:SS)
  String get _formattedTime {
    final ms = _stopwatch.elapsedMilliseconds;
    final seconds = (ms ~/ 1000) % 60;
    final minutes = (ms ~/ 1000) ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Tahta Durumu Yardımcıları ───────────────────────────

  bool _canConnect(int from, int to) =>
      from != to && _isAdjacent(from, to) && !_isEdgeDrawn(from, to);

  /// Aktif düğümden [node]'a kenar çizer (setState içinden çağrılmalı)
  void _connectTo(int node) {
    HapticService.light();
    SoundService.instance.playNodeConnect();
    _drawnEdges.add([_activeNode!, node]);
    _drawnTimes.add(_now);
    _visitedNodes.add(node);
    _activeNode = node;
    _moveCount++;
    _invalidHoverNode = null;
    _addEffect(node, GameEffectKind.connect);
  }

  /// Tahtayı verilen yola ayarlar; yalnızca son kenar animasyonla çizilir
  void _setBoard(List<int> visited, List<List<int>> drawn, {bool animateLast = true}) {
    _visitedNodes
      ..clear()
      ..addAll(visited);
    _drawnEdges
      ..clear()
      ..addAll(drawn.map((e) => [e[0], e[1]]));
    _drawnTimes
      ..clear()
      ..addAll(List.filled(_drawnEdges.length, -10.0));
    if (animateLast && _drawnTimes.isNotEmpty) _drawnTimes.last = _now;
    _activeNode = _visitedNodes.isNotEmpty ? _visitedNodes.last : null;
  }

  void _addEffect(int node, GameEffectKind kind) {
    final now = _now;
    _effects
      ..removeWhere((fx) => now - fx.startTime > GameEffect.lifetime)
      ..add(GameEffect(node, now, kind));
  }

  /// Hatalı hamle: kırmızı darbe + tahta sarsıntısı + titreşim
  void _flashInvalid(int node) {
    HapticService.medium();
    SoundService.instance.playError();
    setState(() {
      _lastInvalidAt = _now;
      _addEffect(node, GameEffectKind.invalid);
    });
  }

  /// Henüz kenar çizilmemişse başlangıç düğümü serbestçe değiştirilebilir
  void _selectStart(int node) {
    _visitedNodes
      ..clear()
      ..add(node);
    _activeNode = node;
    _addEffect(node, GameEffectKind.connect);
  }

  // ─── Dokunma Olayları ────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;

    final hitNode = _findNodeAt(details.localPosition);
    if (hitNode == null) return;

    HapticService.selection();
    setState(() {
      _lastHintEdge = null;
      if (_drawnEdges.isEmpty && hitNode != _activeNode) {
        _selectStart(hitNode);
      }
      if (hitNode == _activeNode) {
        _isDragging = true;
        _currentDragPos = _geometry.toPixel(_nodes[hitNode]);
      }
    });
    if (hitNode != _activeNode) _flashInvalid(hitNode);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isCompleted || _activeNode == null) return;

    final localPos = details.localPosition;
    final hitNode = _findNodeAt(localPos);

    setState(() {
      _currentDragPos = localPos;
      if (hitNode == null || hitNode == _activeNode) {
        _invalidHoverNode = null;
      } else if (_canConnect(_activeNode!, hitNode)) {
        _connectTo(hitNode);
        _currentDragPos = _geometry.toPixel(_nodes[hitNode]);
      }
    });

    // Komşu ama zaten çizilmiş kenar: oyuncuya net geri bildirim (girişte bir kez)
    if (hitNode != null &&
        hitNode != _activeNode &&
        hitNode != _invalidHoverNode &&
        _isAdjacent(_activeNode!, hitNode) &&
        _isEdgeDrawn(_activeNode!, hitNode)) {
      _invalidHoverNode = hitNode;
      _flashInvalid(hitNode);
    }

    if (_drawnEdges.length == _edges.length) _onSolved();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _currentDragPos = null;
      _invalidHoverNode = null;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (_isCompleted) return;

    final hitNode = _findNodeAt(details.localPosition);
    if (hitNode == null || hitNode == _activeNode) return;

    // Henüz kenar yokken: komşu düğüme dokunmak çizer, diğerleri başlangıcı değiştirir
    if (_drawnEdges.isEmpty &&
        (_activeNode == null || !_canConnect(_activeNode!, hitNode))) {
      HapticService.selection();
      setState(() {
        _lastHintEdge = null;
        _selectStart(hitNode);
      });
      return;
    }

    if (_activeNode != null && _canConnect(_activeNode!, hitNode)) {
      // Tıklayarak da bağlantı yapılabilir
      setState(() {
        _lastHintEdge = null;
        _connectTo(hitNode);
      });
      if (_drawnEdges.length == _edges.length) _onSolved();
    } else {
      _flashInvalid(hitNode);
    }
  }

  bool _isAdjacent(int a, int b) {
    return _edges.any(
      (edge) =>
          (edge[0] == a && edge[1] == b) || (edge[0] == b && edge[1] == a),
    );
  }

  bool _isEdgeDrawn(int a, int b) {
    return _drawnEdges.any(
      (edge) =>
          (edge[0] == a && edge[1] == b) || (edge[0] == b && edge[1] == a),
    );
  }

  void _undoLastMove() {
    if (_isCompleted) return;
    if (_drawnEdges.isNotEmpty) {
      HapticService.selection();
      SoundService.instance.playTap();
      setState(() {
        _lastHintEdge = null;
        _drawnEdges.removeLast();
        _drawnTimes.removeLast();
        _visitedNodes.removeLast();
        _activeNode = _visitedNodes.isNotEmpty ? _visitedNodes.last : null;
        _moveCount = _moveCount > 0 ? _moveCount - 1 : 0;
        _mistakes++;
      });
    } else if (_visitedNodes.isNotEmpty) {
      HapticService.selection();
      setState(() {
        _visitedNodes.clear();
        _activeNode = null;
      });
    }
  }

  /// Sıfırla butonu: tahtayı temizler (dolu tahtayı sıfırlamak hata sayılır)
  void _resetLevel() {
    if (_isCompleted) return;
    HapticService.medium();
    SoundService.instance.playTap();
    _ghostTimer?.cancel();
    setState(() {
      if (_drawnEdges.isNotEmpty) _mistakes++;
      _clearBoard();
      _stopwatch.reset();
      _stopwatch.start();
    });
  }

  void _clearBoard() {
    _visitedNodes.clear();
    _drawnEdges.clear();
    _drawnTimes.clear();
    _effects.clear();
    _activeNode = null;
    _moveCount = 0;
    _isDragging = false;
    _currentDragPos = null;
    _lastHintEdge = null;
    _ghostEdges = null;
  }

  /// Seviyeyi baştan oynat (istatistikler ve açılış animasyonu dahil)
  void _restartFresh() {
    _ghostTimer?.cancel();
    setState(() {
      _clearBoard();
      _isCompleted = false;
      _completedAt = null;
      _hintsUsed = 0;
      _mistakes = 0;
      _stopwatch.reset();
      _stopwatch.start();
    });
    _introController.forward(from: 0);
  }

  void _onHintPressed() {
    if (_isCompleted) return;

    final gameProvider = context.read<GameProvider>();
    if (gameProvider.hintCount <= 0) {
      HapticService.medium();
      SoundService.instance.playError();
      _showNoHintsDialog();
      return;
    }

    _handleSmartHint();
  }

  /// İpucu hakkı düşer ve yıldız hesabına işlenir
  void _consumeHint() {
    context.read<GameProvider>().useHint();
    context.read<AchievementProvider>().checkHintUsed();
    _hintsUsed++;
  }

  void _showNoHintsDialog() {
    final l10n = context.l10nRead;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(l10n.outOfHintsTitle, style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          l10n.outOfHintsDesc,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              AdService.instance.showRewarded(
                onRewarded: () {
                  context.read<GameProvider>().addHints(3);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.hintsAdded),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  _handleSmartHint();
                },
              );
            },
            icon: const Icon(Icons.play_circle_rounded, size: 20),
            label: Text(l10n.watchAdReward, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Akıllı ipucu analizi ve yönlendirmesi
  void _handleSmartHint() {
    final l10n = context.l10nRead;

    final hintResult = EulerSolver.getNextHintStep(
      nodeCount: _nodes.length,
      edges: _edges,
      visitedNodes: _visitedNodes,
      drawnEdges: _drawnEdges,
      activeNode: _activeNode,
    );

    if (hintResult == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noHintFound),
        ),
      );
      return;
    }

    // Durum: Kullanıcı birden fazla hamle yapmış ve ya başlangıç noktası yanlış ya da derin çıkmazda
    // Kullanıcının emeğini sessizce silip başa atmak yerine akıllı seçenekler sun
    if (hintResult.isMajorDeadlock && _drawnEdges.length >= 2) {
      _showDeadlockAssistantDialog(hintResult);
      return;
    }

    // Normal akış veya küçük düzeltme (1-2 hamle): Adımı uygula
    _executeHintStep(hintResult);
  }

  /// Derin çıkmaz sokak veya yanlış başlangıçta kullanıcıya yardımcı olan akıllı modal
  void _showDeadlockAssistantDialog(HintStepResult hintResult) {
    final drawnCount = _drawnEdges.length;
    final totalEdges = _edges.length;
    final isWrongStart = hintResult.isWrongStart;
    final fullSol = hintResult.fullSolution;

    // Kullanıcının ilerlemesine göre doğru rotada otomatik çizilecek adım sayısı
    final autoStepsCount = min(
      fullSol.length - 1,
      max(3, min(8, drawnCount)),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final l10n = context.l10nRead;

        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.smartHintTitle,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.smartHintDrawnInfo(drawnCount, totalEdges),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: (isWrongStart ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: (isWrongStart ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isWrongStart ? Icons.info_outline_rounded : Icons.alt_route_rounded,
                        size: 20,
                        color: isWrongStart ? AppColors.error : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isWrongStart ? l10n.wrongStartDesc : l10n.deadEndDesc,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Seçenek 1: Çözüm Yolunu Önizle (Tahtayı silmez!)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _activateGhostPreview(hintResult);
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 20),
                  label: Text(
                    l10n.previewSolution,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 10),

                // Seçenek 2: Doğru Rotaya Geç ve Otomatik İlerlet
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _jumpToCorrectPath(hintResult, autoStepsCount);
                  },
                  icon: const Icon(Icons.fast_forward_rounded, size: 20),
                  label: Text(
                    l10n.switchToRoute(autoStepsCount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    l10n.cancelHint,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Çözüm yolunu tahtayı silmeden 10 saniye boyunca parlayan numaralı kılavuz olarak gösterir
  void _activateGhostPreview(HintStepResult hintResult) {
    _consumeHint();

    HapticService.light();
    SoundService.instance.playHint();

    final fullSol = hintResult.fullSolution;
    final ghost = <List<int>>[];
    for (int i = 0; i < fullSol.length - 1; i++) {
      ghost.add([fullSol[i], fullSol[i + 1]]);
    }

    setState(() {
      _ghostEdges = ghost;
      _ghostTimer?.cancel();
      _ghostTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _ghostEdges = null);
      });
    });

    final l10n = context.l10nRead;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.visibility_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.previewActiveSnackBar,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.close,
          textColor: AppColors.accent,
          onPressed: () {
            _ghostTimer?.cancel();
            setState(() => _ghostEdges = null);
          },
        ),
      ),
    );
  }

  /// Doğru rotaya geçerek kullanıcının ilerleme seviyesine kadar olan adımları hazır çizer
  void _jumpToCorrectPath(HintStepResult hintResult, int stepsToDraw) {
    _consumeHint();

    HapticService.medium();
    SoundService.instance.playHint();

    final fullSol = hintResult.fullSolution;
    final validSteps = min(stepsToDraw, fullSol.length - 1);

    setState(() {
      _ghostTimer?.cancel();
      _ghostEdges = null;

      final visited = [fullSol[0]];
      final drawn = <List<int>>[];
      for (int i = 0; i < validSteps; i++) {
        drawn.add([fullSol[i], fullSol[i + 1]]);
        visited.add(fullSol[i + 1]);
      }
      _setBoard(visited, drawn);
      // Rota kenarlarını sırayla "akarak" çiz
      for (int i = 0; i < _drawnTimes.length; i++) {
        _drawnTimes[i] = _now + i * 0.06;
      }
      _lastHintEdge = _drawnEdges.isNotEmpty ? _drawnEdges.last : null;
      _moveCount = _drawnEdges.length;

      // Sonraki adımları kılavuz olarak göster
      if (validSteps < fullSol.length - 1) {
        final upcoming = <List<int>>[];
        for (int i = validSteps; i < min(validSteps + 3, fullSol.length - 1); i++) {
          upcoming.add([fullSol[i], fullSol[i + 1]]);
        }
        _ghostEdges = upcoming;
        _ghostTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _ghostEdges = null);
        });
      }
    });
    if (_drawnEdges.length == _edges.length) _onSolved();

    final l10n = context.l10nRead;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.switchedToRouteSnackBar(validSteps),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Tek adımlık doğrudan ipucunu uygular
  void _executeHintStep(HintStepResult hintResult) {
    _consumeHint();

    HapticService.light();
    SoundService.instance.playHint();

    setState(() {
      if (hintResult.didRollback) {
        _setBoard(hintResult.rollbackVisitedNodes, hintResult.rollbackDrawnEdges,
            animateLast: false);
      } else if (_visitedNodes.isEmpty) {
        _setBoard([hintResult.fromNode], const []);
      }

      final newEdge = [hintResult.fromNode, hintResult.toNode];
      _drawnEdges.add(newEdge);
      _drawnTimes.add(_now);
      _visitedNodes.add(hintResult.toNode);
      _activeNode = hintResult.toNode;
      _lastHintEdge = newEdge;
      _moveCount = _drawnEdges.length;
      _addEffect(hintResult.toNode, GameEffectKind.connect);

      // Sonraki kılavuz adımları göster (varsa)
      if (hintResult.upcomingSteps.length > 1) {
        _ghostEdges = hintResult.upcomingSteps.sublist(1);
        _ghostTimer?.cancel();
        _ghostTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _ghostEdges = null);
        });
      }
    });
    if (_drawnEdges.length == _edges.length) _onSolved();

    final l10n = context.l10nRead;
    final message = switch (hintResult.kind) {
      HintKind.start => l10n.hintStartMsg,
      HintKind.next => l10n.hintNextMsg,
      HintKind.rollback => l10n.hintRollbackMsg(hintResult.rollbackCount),
      HintKind.wrongStart => l10n.hintWrongStartMsg,
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Tamamlama ───────────────────────────────────────────

  /// 3 yıldız: ipucusuz ve en fazla 3 hata; 2 yıldız: en fazla 1 ipucu ve 10 hata.
  /// (Hamle sayısı her zaman kenar sayısına eşit olduğundan yıldız ölçütü olamaz.)
  int _calculateStars() {
    if (_hintsUsed == 0 && _mistakes <= 3) return 3;
    if (_hintsUsed <= 1 && _mistakes <= 10) return 2;
    return 1;
  }

  void _onSolved() {
    if (_isCompleted) return;
    _ghostTimer?.cancel();
    _stopwatch.stop();
    _elapsedMs = _stopwatch.elapsedMilliseconds;

    setState(() {
      _isCompleted = true;
      _isDragging = false;
      _currentDragPos = null;
      _ghostEdges = null;
      _completedAt = _now;
    });

    HapticService.heavy();
    SoundService.instance.playLevelComplete();
    ScaffoldMessenger.of(context).clearSnackBars();

    final stars = _calculateStars();
    if (stars == 3) {
      _consecutivePerfects++;
    } else {
      _consecutivePerfects = 0;
    }

    // İlerlemeyi hemen kaydet (oyuncu sonuç ekranını görmeden çıksa bile)
    context.read<GameProvider>().completeLevel(
      difficulty: widget.difficulty,
      levelId: widget.levelId,
      stars: stars,
      moves: _moveCount,
      timeMs: _elapsedMs,
    );
    final achievementProvider = context.read<AchievementProvider>();
    achievementProvider.checkSpeedDemon(_elapsedMs);
    achievementProvider.checkPerfectStreak(_consecutivePerfects);

    // Işık dalgası şeklin üzerinden geçsin, sonra sonuç ekranı
    Future.delayed(const Duration(milliseconds: 1150), () {
      if (mounted) _showCompletionDialog(stars);
    });
  }

  void _showCompletionDialog(int stars) {
    final l10n = context.l10nRead;
    final locale = context.read<SettingsProvider>().locale;
    final hasNext = context.read<GameProvider>().hasNextLevel(widget.difficulty, widget.levelId);
    final seconds = (_elapsedMs ~/ 1000) % 60;
    final minutes = (_elapsedMs ~/ 1000) ~/ 60;

    // Geçiş reklamı, oyuncu sonuç ekranından ayrılırken gösterilir
    void leave(VoidCallback then) {
      Navigator.of(context).pop();
      AdService.instance.onLevelCompleted(onAdClosed: () {
        if (mounted) then();
      });
    }

    LevelCompleteDialog.show(
      context,
      stars: stars,
      levelLabel:
          '${_difficulty.localizedFor(locale)} • ${l10n.levelAndName(widget.levelId, _currentLevel.localizedName(locale))}',
      moves: _moveCount,
      timeText: l10n.formatTime(minutes, seconds),
      hintsUsed: _hintsUsed,
      gradient: _difficulty.gradient,
      hasNextLevel: hasNext,
      onMenu: () => leave(() => context.pop()),
      onReplay: () => leave(_restartFresh),
      onNext: () => leave(() {
        if (hasNext) {
          context.pushReplacement('/game/${widget.levelId + 1}?d=${widget.difficulty}');
        } else {
          final messenger = ScaffoldMessenger.of(context);
          context.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.difficultyCompleted),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }),
    );

    // Başarım bildirimlerini göster (sonuç kartı belirdikten kısa süre sonra)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _showAchievementNotifications();
    });
  }

  void _showAchievementNotifications() {
    final achievementProvider = context.read<AchievementProvider>();
    if (!achievementProvider.hasPendingNotifications) return;

    final locale = context.read<SettingsProvider>().locale;
    final pending = achievementProvider.consumePendingNotifications();
    for (final achievement in pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(achievement.icon, color: achievement.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 ${achievement.localizedTitleFor(locale)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      achievement.localizedSubtitleFor(locale),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      );
    }
  }

  // ─── Arayüz ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.watch<SettingsProvider>().locale;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    final progress = _edges.isEmpty ? 0.0 : _drawnEdges.length / _edges.length;

    return Scaffold(
      appBar: AppBar(
        // Dar ekranda süre/hamle sayaçlarıyla çakışmasın: taşmak yerine küçülür
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${l10n.level} ${widget.levelId}', style: AppTextStyles.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: _difficulty.gradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _difficulty.localized(context),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                _currentLevel.localizedName(locale),
                style: AppTextStyles.labelSmall.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          // Süre sayacı
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: StreamBuilder(
                stream: _secondTicks,
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18,
                        color: onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(
                        _formattedTime,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: onSurface.withValues(alpha: 0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Hamle sayacı
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 20),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_moveCount',
                      key: ValueKey(_moveCount),
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme çubuğu + kenar bilgisi
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(height: 8, color: onSurface.withValues(alpha: 0.08)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(gradient: _difficulty.gradient),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.drawnLinesProgress(_drawnEdges.length, _edges.length),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Çizim Alanı
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        // Sürükleme ilk dokunulan noktadan başlasın: varsayılan
                        // (start) kaydırma eşiği sonrası konumu verir ve parmak
                        // o anda düğümün dokunma alanından çıkmış olabilir.
                        dragStartBehavior: DragStartBehavior.down,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _onTapUp,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_pulseController, _introController]),
                          builder: (context, child) {
                            final now = _now;
                            // Hatalı hamlede kısa, sönümlenen yatay sarsıntı
                            final shakeT = now - _lastInvalidAt;
                            final shake = shakeT < 0.35
                                ? sin(shakeT * 70) * 7 * (1 - shakeT / 0.35)
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(shake, 0),
                              child: CustomPaint(
                                size: _canvasSize,
                                painter: GamePainter(
                                  nodes: _nodes,
                                  edges: _edges,
                                  drawnEdges: _drawnEdges,
                                  drawnTimes: _drawnTimes,
                                  lastHintEdge: _lastHintEdge,
                                  activeNode: _activeNode,
                                  visitedNodes: _visitedNodes,
                                  isDragging: _isDragging,
                                  dragPosition: _currentDragPos,
                                  isDark: Theme.of(context).brightness == Brightness.dark,
                                  pulseValue: _pulseController.value,
                                  time: now,
                                  introProgress: _introController.value,
                                  completedAt: _completedAt,
                                  effects: _effects,
                                  ghostEdges: _ghostEdges,
                                  startNodes: _showStartHints && _validStartNodes.length == 2
                                      ? _validStartNodes
                                      : const [],
                                  pathStartColor: primary,
                                  pathEndColor: AppColors.secondary,
                                  nodeRadius: _nodeRadius,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Kılavuz / Önizleme aktifken üstte bilgilendirme çipi
                    if (_ghostEdges != null)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _ghostEdges!.length > 2
                                        ? l10n.guideFullSolution
                                        : l10n.guideNextSteps,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _ghostTimer?.cancel();
                                    setState(() => _ghostEdges = null);
                                  },
                                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Alt Buton Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.undo_rounded,
                    label: l10n.undo,
                    onTap: _undoLastMove,
                  ),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: l10n.reset,
                    onTap: _resetLevel,
                  ),
                  _ActionButton(
                    icon: Icons.lightbulb_rounded,
                    label: l10n.hint,
                    badge: '${context.watch<GameProvider>().hintCount}',
                    highlight: true,
                    onTap: _onHintPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aksiyon butonu widget'ı (isteğe bağlı bildirim rozeti destekli)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool highlight;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.badge,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: highlight ? null : primary.withValues(alpha: 0.1),
                  gradient: highlight
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD86B), AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  boxShadow: highlight
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(icon, color: highlight ? Colors.black87 : primary),
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey(badge),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
