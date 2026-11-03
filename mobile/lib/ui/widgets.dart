import 'package:flutter/material.dart';

import 'theme.dart';

/// Status colours: text on tint.
enum Tone {
  green(Palette.greenInk, Palette.greenTint),
  amber(Palette.amberInk, Palette.amberChip),
  red(Palette.redText, Palette.redTint),
  blue(Palette.blue, Palette.blueTint),
  neutral(Palette.ink2, Palette.soft);

  final Color text;
  final Color tint;
  const Tone(this.text, this.tint);
}

class StatusPill extends StatelessWidget {
  final String label;
  final Tone tone;

  const StatusPill(this.label, this.tone, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tone.text)),
      );
}

/// A tinted message box: an icon and a few lines of text, optionally with an action.
class Callout extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final Widget child;
  final Widget? action;

  const Callout({super.key, required this.icon, required this.tone, required this.child, this.action});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: tone.text),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(color: tone.text, fontSize: 14, height: 1.4),
              child: child,
            ),
          ),
          ?action,
        ]),
      );
}

/// White rounded panel with a hairline border.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;

  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.borderColor = Palette.line});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const InitialsAvatar(this.name, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = (parts.first.isEmpty ? '' : parts.first[0]) + (parts.length > 1 ? parts.last[0] : '');
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Palette.green, shape: BoxShape.circle),
      child: Text(initials.toUpperCase(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.32)),
    );
  }
}

/// Small grey label above a value.
class Fact extends StatelessWidget {
  final String label;
  final String value;
  final Key? valueKey;

  const Fact(this.label, this.value, {super.key, this.valueKey});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Palette.muted)),
        const SizedBox(height: 2),
        Text(value, key: valueKey, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]);
}

/// Survey C: a boundary pillar seen from above, open on the right, around a gold survey point.
class BrandMark extends StatelessWidget {
  final double size;
  final Color color;

  const BrandMark({super.key, this.size = 32, this.color = Palette.green});

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'Cadastra', child: CustomPaint(size: Size.square(size), painter: _SurveyCPainter(color)));
}

class _SurveyCPainter extends CustomPainter {
  final Color color;

  const _SurveyCPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100; // drawn on the brand's 100-unit grid
    final small = size.width < 24;
    final c = Path()
      ..moveTo(71 * u, 29 * u)
      ..lineTo(50 * u, 8 * u)
      ..lineTo(8 * u, 50 * u)
      ..lineTo(50 * u, 92 * u)
      ..lineTo(71 * u, 71 * u);
    canvas.drawPath(
      c,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (small ? 15 : 13) * u
        ..strokeJoin = StrokeJoin.miter,
    );
    canvas.drawCircle(Offset(50 * u, 50 * u), (small ? 12 : 10) * u, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(_SurveyCPainter old) => old.color != color;
}
