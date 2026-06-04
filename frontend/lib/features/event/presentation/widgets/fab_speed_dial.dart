import 'package:flutter/material.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';

/// + 버튼을 누르면 두 개의 미니 FAB이 펼쳐지는 SpeedDial
/// - 카메라(OCR) 버튼
/// - 일정 직접 추가 버튼
class FabSpeedDial extends StatefulWidget {
  final VoidCallback onAddEvent;
  final VoidCallback onOcr;

  const FabSpeedDial({
    super.key,
    required this.onAddEvent,
    required this.onOcr,
  });

  @override
  State<FabSpeedDial> createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends State<FabSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
        parent: _controller, curve: Curves.easeOutBack);
    _rotateAnim = Tween<double>(begin: 0, end: 0.375)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  void _showAddTypeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(leading: const Icon(Icons.calendar_today_outlined), title: const Text('일정'), onTap: () { Navigator.pop(ctx); widget.onAddEvent(); }),
            ListTile(leading: const Icon(Icons.check_box_outlined), title: const Text('할일'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.loop_outlined), title: const Text('습관'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.swap_horiz_outlined), title: const Text('구간'), onTap: () { Navigator.pop(ctx); widget.onAddEvent(); }),
            ListTile(leading: const Icon(Icons.horizontal_rule_outlined), title: const Text('마스킹 테이프'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.grid_view_outlined), title: const Text('배경'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.crop_square_outlined), title: const Text('테두리'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.tag_outlined), title: const Text('날짜 태그'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.emoji_emotions_outlined), title: const Text('데코 스티커'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.star_border_outlined), title: const Text('날짜 스티커'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.format_color_fill_outlined), title: const Text('날짜색'), onTap: () => Navigator.pop(ctx)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _close() {
    if (_open) {
      setState(() => _open = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── OCR 카메라 버튼 ──────────────────────────
        ScaleTransition(
          scale: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FabLabel(label: 'OCR 일정 추가'),
                const SizedBox(width: 10),
                _MiniButton(
                  icon: Icons.camera_alt_outlined,
                  color: AppColors.secondary,
                  onPressed: () {
                    _close();
                    widget.onOcr();
                  },
                ),
              ],
            ),
          ),
        ),

        // ── 직접 추가 버튼 ──────────────────────────
        ScaleTransition(
          scale: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FabLabel(label: '일정 직접 추가'),
                const SizedBox(width: 10),
                _MiniButton(
                  icon: Icons.add_rounded,
                  color: AppColors.accentOrange,
                  onPressed: () {
                    _close();
                    _showAddTypeSheet(context);
                  },
                ),
              ],
            ),
          ),
        ),

        // ── 메인 FAB ──────────────────────────────────
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          child: RotationTransition(
            turns: _rotateAnim,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _FabLabel extends StatelessWidget {
  final String label;
  const _FabLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
