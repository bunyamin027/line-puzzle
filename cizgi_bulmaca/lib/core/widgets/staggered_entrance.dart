import 'package:flutter/material.dart';

/// Çizgi Bulmaca — Kademeli Giriş Animasyonu
/// Çocuğunu [delay] kadar bekledikten sonra aşağıdan kayarak ve belirerek gösterir.
/// Liste/kart dizilerinde index * 60ms gibi gecikmelerle "akış" hissi verir.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.beginOffset = const Offset(0, 0.18),
    this.beginScale = 1.0,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.beginOffset, end: Offset.zero).animate(_curve),
        child: widget.beginScale == 1.0
            ? widget.child
            : ScaleTransition(
                scale: Tween(begin: widget.beginScale, end: 1.0).animate(_curve),
                child: widget.child,
              ),
      ),
    );
  }
}
