import 'package:flutter/material.dart';

class AppToast {
  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    _show(context, message, duration, const Color(0xFF16A34A), Icons.check_circle);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    _show(context, message, duration, const Color(0xFFDC2626), Icons.error_rounded);
  }

  static void _show(BuildContext context, String message, Duration duration, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastContent(message: message, color: color, icon: icon, onClose: () => entry.remove()),
    );
    overlay.insert(entry);
    Future.delayed(duration, () {
      try { entry.remove(); } catch (_) {}
    });
  }
}

class _ToastContent extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onClose;
  const _ToastContent({required this.message, required this.color, required this.icon, required this.onClose});

  @override
  State<_ToastContent> createState() => _ToastContentState();
}

class _ToastContentState extends State<_ToastContent> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();
  late final Animation<Offset> _offset = Tween(begin: const Offset(0, -0.1), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 28,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _offset,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





