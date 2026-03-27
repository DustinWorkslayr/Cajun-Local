import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in replacement for [RefreshIndicator] styled to the app's "Digital
/// Curator" navy/gold palette.
///
/// Usage is identical to [RefreshIndicator]:
/// ```dart
/// AppRefreshIndicator(
///   onRefresh: _onRefresh,
///   child: listView,
/// )
/// ```
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> with TickerProviderStateMixin {
  // ── drag tracking ──────────────────────────────────────────────────────────
  double _dragExtent = 0.0;
  bool _isRefreshing = false;
  bool _isDragging = false;

  static const double _triggerDistance = 72.0;
  static const double _indicatorHeight = 68.0;

  // ── animations ─────────────────────────────────────────────────────────────
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);

    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── progress (0..1) ────────────────────────────────────────────────────────
  double get _progress => (_dragExtent / _triggerDistance).clamp(0.0, 1.0);

  // ── scroll notification handler ────────────────────────────────────────────
  bool _handleScroll(ScrollNotification notification) {
    if (_isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      // Only the overscroll region (already at top)
      final metrics = notification.metrics;
      if (metrics.pixels <= 0) {
        final delta = -(notification.scrollDelta ?? 0);
        if (delta > 0) {
          setState(() {
            _isDragging = true;
            _dragExtent = (_dragExtent + delta).clamp(0.0, _triggerDistance * 1.4);
          });
        }
      }
    }

    if (notification is ScrollEndNotification || notification is UserScrollNotification) {
      if (_isDragging && !_isRefreshing) {
        if (_dragExtent >= _triggerDistance) {
          _startRefresh();
        } else {
          _collapseDrag();
        }
      }
    }

    if (notification is OverscrollNotification) {
      if (!_isRefreshing) {
        setState(() {
          _isDragging = true;
          _dragExtent = (_dragExtent + (-(notification.overscroll))).clamp(0.0, _triggerDistance * 1.4);
        });
      }
    }

    return false;
  }

  void _startRefresh() async {
    setState(() {
      _isRefreshing = true;
      _isDragging = false;
      _dragExtent = _triggerDistance;
    });
    _spinController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
        setState(() {
          _isRefreshing = false;
          _dragExtent = 0;
        });
      }
    }
  }

  void _collapseDrag() {
    setState(() {
      _isDragging = false;
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final show = _dragExtent > 0 || _isRefreshing;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(
        children: [
          // ── the actual scrollable content ────────────────────────────────
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(top: show ? (_isRefreshing ? _indicatorHeight : _progress * _indicatorHeight) : 0),
            child: widget.child,
          ),

          // ── custom pull indicator ────────────────────────────────────────
          if (show)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _isRefreshing ? _indicatorHeight : _progress * _indicatorHeight,
              child: _PullIndicatorContent(
                progress: _progress,
                isRefreshing: _isRefreshing,
                spinController: _spinController,
                pulseScale: _pulseScale,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicator content widget
// ─────────────────────────────────────────────────────────────────────────────

class _PullIndicatorContent extends StatelessWidget {
  const _PullIndicatorContent({
    required this.progress,
    required this.isRefreshing,
    required this.spinController,
    required this.pulseScale,
  });

  final double progress;
  final bool isRefreshing;
  final AnimationController spinController;
  final Animation<double> pulseScale;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: AppTheme.specOffWhite,
        alignment: Alignment.center,
        child: Opacity(opacity: progress.clamp(0.0, 1.0), child: isRefreshing ? _buildSpinning() : _buildPulling()),
      ),
    );
  }

  Widget _buildPulling() {
    // While pulling: arc progress ring + explore icon + "Pull to refresh" label
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: CustomPaint(
            painter: _ArcPainter(progress: progress, color: AppTheme.specGold),
            child: Center(
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.specNavy.withValues(alpha: 0.6 + 0.4 * progress),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(progress >= 1.0 ? 'Release to refresh' : 'Pull to refresh'),
      ],
    );
  }

  Widget _buildSpinning() {
    // While loading: pulsing gold background circle + spinning explore icon
    return ScaleTransition(
      scale: pulseScale,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.specNavy,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.specNavy.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: AnimatedBuilder(
          animation: spinController,
          builder: (context, _) {
            return Transform.rotate(
              angle: spinController.value * 2 * math.pi,
              child: const Icon(Icons.explore_rounded, size: 20, color: AppTheme.specGold),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc progress painter
// ─────────────────────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
