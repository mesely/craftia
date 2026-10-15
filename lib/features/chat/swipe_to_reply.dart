import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';

/// Drag a bubble to the right to answer it (like in every chat app). The icon appears as you
/// pull and a tiny vibration confirms; letting go springs the bubble back. Long-press offers the
/// same action in a menu, so the gesture is never the only way.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const _trigger = 56.0;
  static const _max = 72.0;

  late final AnimationController _back =
      AnimationController(vsync: this, duration: AppDurations.normal)
        ..addListener(() {
          if (_back.isAnimating) {
            setState(
              () => _dx = _from * (1 - Curves.easeOut.transform(_back.value)),
            );
          }
        });
  double _dx = 0;
  bool _armed = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    final next = (_dx + d.delta.dx).clamp(0.0, _max);
    if (!_armed && next >= _trigger) {
      _armed = true;
      HapticFeedback.mediumImpact();
    }
    if (_armed && next < _trigger) _armed = false;
    setState(() => _dx = next);
  }

  double _from = 0;

  void _end(DragEndDetails _) {
    if (_dx >= _trigger) widget.onReply();
    _from = _dx;
    _armed = false;
    _back
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: (_dx / _trigger).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: UstaIcon(
                    UstaIcons.reply,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}
