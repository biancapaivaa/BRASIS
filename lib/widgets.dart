import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data.dart';

const forest = Color(0xFF245C45);
const sun = Color(0xFFF2BE35);
const clay = Color(0xFFCC6246);
const river = Color(0xFF287C9B);
const cream = Color(0xFFFFF3D6);
const ink = Color(0xFF183C32);
const paper = Color(0xFFFFFAEA);
const muted = Color(0xFF69786E);

IconData journeyIcon(String? name) => switch (name) {
  'music' => Icons.music_note_rounded,
  'food' => Icons.restaurant_rounded,
  'art' => Icons.palette_rounded,
  'story' => Icons.auto_stories_rounded,
  'building' => Icons.account_balance_rounded,
  'party' => Icons.celebration_rounded,
  'passport' => Icons.menu_book_rounded,
  'star' => Icons.auto_awesome_rounded,
  _ => Icons.explore_rounded,
};

class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color, foreground;
  final IconData icon;
  final bool busy;
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = sun,
    this.foreground = ink,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed == null ? const Color(0xFFCCD2C9) : foreground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Transform.translate(
        offset: const Offset(0, -4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: const Color(0xFFE0E4DA),
            disabledForegroundColor: muted,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: busy ? null : onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 22),
            ],
          ),
        ),
      ),
    ),
  );
}

class Sticker extends StatelessWidget {
  final String label;
  final Color color, foreground;
  final IconData? icon;
  const Sticker(
    this.label, {
    super.key,
    this.color = sun,
    this.foreground = ink,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  color: ink,
                  letterSpacing: -.8,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    ),
  );
}

class ProgressCard extends StatelessWidget {
  final int points, completed, level;
  final double progress;
  const ProgressCard({
    super.key,
    required this.points,
    required this.completed,
    required this.level,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: forest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: sun, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$points XP',
                style: const TextStyle(
                  fontSize: 25,
                  color: cream,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Sticker('NÍVEL $level', color: sun),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: sun,
            minHeight: 9,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Text(
                '$completed missões carimbadas',
                style: const TextStyle(color: cream, fontSize: 11),
              ),
            ),
            Text(
              '${300 - points % 300} XP para subir',
              style: const TextStyle(color: cream, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class MissionCard extends StatelessWidget {
  final BrasisRecord mission;
  final String status;
  final bool locked;
  final VoidCallback onTap;
  const MissionCard({
    super.key,
    required this.mission,
    required this.status,
    required this.onTap,
    this.locked = false,
  });
  @override
  Widget build(BuildContext context) {
    final region = regions[(mission['region_order'] as int) - 1];
    final done = status == 'completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: locked ? const Color(0xFFF1F0E8) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
          side: BorderSide(
            color: done ? region.color : const Color(0xFFE4E7D9),
            width: done ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 65,
                  decoration: BoxDecoration(
                    color: locked ? const Color(0xFFE4E6DD) : region.light,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    locked
                        ? Icons.lock_rounded
                        : done
                        ? Icons.verified_rounded
                        : journeyIcon(mission['icon'] as String?),
                    size: 31,
                    color: locked ? muted : region.color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARADA ${mission['step_order']} · ${mission['category']}'
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: .7,
                          color: locked ? muted : region.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mission['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          height: 1.2,
                          color: locked ? muted : ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: [
                          Text(
                            '+${mission['points']} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: ink,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            locked
                                ? 'Libere a parada anterior'
                                : statusLabel(status),
                            style: TextStyle(
                              fontSize: 11,
                              color: done ? forest : muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: locked ? muted : region.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final BrasisRecord achievement;
  final bool unlocked;
  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.unlocked,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: unlocked ? Colors.white : const Color(0xFFF0F0E9),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(
        color: unlocked ? sun : const Color(0xFFE2E4DA),
        width: 1.5,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: unlocked ? sun : const Color(0xFFDEE3D8),
          child: Icon(
            unlocked
                ? journeyIcon(achievement['icon'] as String?)
                : Icons.lock_outline_rounded,
            color: unlocked ? ink : muted,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['name'] as String,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                achievement['description'] as String,
                style: const TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
              const SizedBox(height: 9),
              Text(
                unlocked ? 'JÁ É SUA! ✦' : 'AINDA TEM HISTÓRIA PELA FRENTE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w900,
                  color: unlocked ? forest : muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PassportStamp extends StatelessWidget {
  final RegionInfo region;
  final bool unlocked;
  final int completed, total;
  const PassportStamp({
    super.key,
    required this.region,
    required this.unlocked,
    required this.completed,
    required this.total,
  });
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: (region.order.isEven ? 1 : -1) * .045,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: unlocked ? region.light : const Color(0xFFF0F0E8),
        border: Border.all(
          color: unlocked ? region.color : const Color(0xFFB8BFB3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
            size: 25,
            color: unlocked ? region.color : muted,
          ),
          const SizedBox(height: 5),
          Text(
            region.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: unlocked ? region.color : muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            unlocked ? 'EU DESCOBRI!' : '$completed/$total paradas',
            style: TextStyle(
              fontSize: 9,
              color: unlocked ? region.color : muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// Ilustrações vetoriais próprias, renderizadas no Flutter, sem download de imagens.
class RegionalArt extends StatelessWidget {
  final int region;
  final double height;
  const RegionalArt({super.key, required this.region, this.height = 190});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Ilustração cultural da região ${regions[region - 1].name}',
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _RegionPainter(region)),
    ),
  );
}

class _RegionPainter extends CustomPainter {
  final int region;
  _RegionPainter(this.region);
  void rect(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color color, [
    double radius = 6,
  ]) => c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
    Paint()..color = color,
  );
  void ellipse(Canvas c, double x, double y, double w, double h, Color color) =>
      c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
  void line(Canvas c, Offset a, Offset b, Color color, [double width = 3]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void path(Canvas c, List<Offset> points, Color color) {
    final p = Path()..addPolygon(points, true);
    c.drawPath(p, Paint()..color = color);
  }

  void star(Canvas c, double x, double y, double r, Color color) {
    path(
      c,
      List.generate(8, (i) {
        final a = math.pi * i / 4;
        final n = i.isEven ? r : r * .3;
        return Offset(x + math.cos(a) * n, y + math.sin(a) * n);
      }),
      color,
    );
  }

  void palm(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    line(
      c,
      const Offset(0, 0),
      const Offset(-5, 85),
      const Color(0xFF8A5C36),
      8,
    );
    for (final dx in [-40.0, -25.0, 25.0, 40.0]) {
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(dx, -35, dx * 1.4, 9)
        ..quadraticBezierTo(dx, -3, 0, 0);
      c.drawPath(p, Paint()..color = forest);
    }
    c.restore();
  }

  void house(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color color, {
    bool roof = true,
  }) {
    rect(c, x, y, w, h, color, 2);
    if (roof) {
      path(c, [
        Offset(x - 5, y),
        Offset(x + w / 2, y - 23),
        Offset(x + w + 5, y),
      ], clay);
    }
    rect(c, x + w * .39, y + h * .55, w * .23, h * .45, forest, 12);
    for (final dx in [.14, .64]) {
      rect(c, x + w * dx, y + 13, w * .2, 19, cream, 3);
    }
  }

  void note(Canvas c, double x, double y, Color color) {
    ellipse(c, x, y, 12, 8, color);
    line(c, Offset(x + 10, y + 3), Offset(x + 10, y - 20), color, 3);
    line(c, Offset(x + 10, y - 20), Offset(x + 20, y - 15), color, 3);
  }

  void drum(Canvas c, double x, double y, Color color) {
    path(c, [
      Offset(x, y),
      Offset(x + 45, y),
      Offset(x + 38, y + 58),
      Offset(x + 7, y + 58),
    ], color);
    for (var i = 0; i < 3; i++) {
      line(
        c,
        Offset(x + 5 + i * 14, y + 5),
        Offset(x + 10 + i * 11, y + 52),
        cream,
        2,
      );
    }
    ellipse(c, x - 3, y - 8, 51, 18, ink);
    ellipse(c, x + 1, y - 6, 43, 12, sun);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    final scale = math.min(size.width / 360, size.height / 200);
    c.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 200 * scale) / 2,
    );
    c.scale(scale);
    final info = regions[region - 1];
    ellipse(c, 25, 25, 310, 170, info.light);
    ellipse(c, 265, 15, 45, 45, sun);
    star(c, 36, 38, 13, clay);
    star(c, 330, 115, 12, river);
    ellipse(c, 34, 177, 292, 14, info.color.withValues(alpha: .12));
    switch (region) {
      case 1:
        palm(c, 72, 78, .9);
        palm(c, 285, 65, .7);
        // Fachadas coloridas e uma canoa, encontro de cidade e rio.
        house(c, 110, 87, 60, 82, clay);
        house(c, 173, 77, 52, 92, sun);
        house(c, 228, 101, 43, 68, river);
        rect(c, 15, 160, 330, 17, river, 20);
        path(c, const [
          Offset(64, 153),
          Offset(171, 153),
          Offset(153, 177),
          Offset(84, 177),
        ], sun);
        line(c, const Offset(120, 139), const Offset(148, 173), ink, 4);
        drum(c, 267, 120, clay);
        note(c, 300, 86, forest);
      case 2:
        // Sobrados, bandeirolas e a sombrinha associada aos passistas de frevo.
        house(c, 45, 100, 55, 72, river);
        house(c, 103, 79, 60, 93, sun);
        house(c, 167, 94, 51, 78, clay);
        for (var i = 0; i < 8; i++) {
          final x = 37.0 + i * 36;
          final y = 48 + math.sin(i * .4) * 12;
          line(c, Offset(x, y), Offset(x + 36, y + 4), ink, 1.4);
          path(c, [
            Offset(x + 2, y),
            Offset(x + 14, y + 22),
            Offset(x + 28, y + 3),
          ], [sun, clay, river, forest][i % 4]);
        }
        final umbrella = Path()
          ..moveTo(229, 129)
          ..quadraticBezierTo(270, 52, 318, 129)
          ..close();
        c.drawPath(umbrella, Paint()..color = clay);
        path(c, const [
          Offset(229, 129),
          Offset(270, 88),
          Offset(270, 129),
        ], sun);
        path(c, const [
          Offset(270, 129),
          Offset(270, 88),
          Offset(295, 129),
        ], river);
        line(c, const Offset(270, 111), const Offset(270, 171), ink, 4);
        note(c, 312, 74, forest);
      case 3:
        // Referência livre às curvas de Brasília e à viola de cocho.
        rect(c, 100, 133, 138, 39, cream, 3);
        for (var i = 0; i < 6; i++) {
          final p = Path()
            ..moveTo(102 + i * 22, 132)
            ..quadraticBezierTo(171, 140, 166 + i * 2, 60);
          c.drawPath(
            p,
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5,
          );
        }
        rect(c, 89, 172, 164, 6, clay, 3);
        c.save();
        c.translate(270, 142);
        c.rotate(.35);
        ellipse(c, -25, -8, 51, 62, clay);
        ellipse(c, -19, -29, 38, 40, clay);
        rect(c, -6, -84, 12, 75, const Color(0xFF8B5F31), 2);
        ellipse(c, -9, -9, 18, 18, ink);
        for (var i = 0; i < 3; i++) {
          line(c, Offset(-3 + i * 3, -79), Offset(-3 + i * 3, 39), cream, 1);
        }
        c.restore();
        note(c, 302, 61, river);
        house(c, 35, 127, 44, 47, sun);
      case 4:
        // Arcos urbanos e percussão, sem reduzir a região a uma única cidade.
        path(c, const [
          Offset(20, 158),
          Offset(93, 58),
          Offset(151, 159),
        ], forest);
        path(c, const [
          Offset(90, 167),
          Offset(168, 89),
          Offset(227, 167),
        ], const Color(0xFF8FB5A6));
        rect(c, 47, 132, 207, 40, cream, 1);
        for (var i = 0; i < 7; i++) {
          rect(c, 55 + i * 28, 141, 19, 36, river, 12);
        }
        rect(c, 47, 128, 207, 7, clay, 2);
        ellipse(c, 253, 110, 67, 67, clay);
        ellipse(c, 260, 117, 53, 53, sun);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          ellipse(
            c,
            282 + math.cos(a) * 30,
            140 + math.sin(a) * 30,
            7,
            9,
            cream,
          );
        }
        note(c, 286, 80, forest);
        note(c, 230, 71, clay);
      case 5:
        // Araucária, palco de festa e cuia de chimarrão.
        line(
          c,
          const Offset(74, 53),
          const Offset(74, 178),
          const Color(0xFF80532E),
          8,
        );
        for (var i = 0; i < 3; i++) {
          final y = 65.0 + i * 24;
          line(c, Offset(74, y + 15), Offset(29 - i * 3, y), forest, 9);
          line(c, Offset(74, y + 15), Offset(119 + i * 3, y), forest, 9);
        }
        house(c, 129, 105, 70, 67, sun);
        line(c, const Offset(129, 105), const Offset(199, 172), ink, 3);
        line(c, const Offset(199, 105), const Offset(129, 172), ink, 3);
        // Boi cenográfico: tecido e chifres, referência à brincadeira catarinense.
        rect(c, 206, 133, 69, 37, river, 16);
        ellipse(c, 263, 119, 31, 36, cream);
        line(c, const Offset(268, 124), const Offset(260, 112), ink, 3);
        line(c, const Offset(285, 124), const Offset(294, 111), ink, 3);
        ellipse(c, 283, 132, 4, 4, ink);
        for (var i = 0; i < 3; i++) {
          ellipse(c, 218 + i * 17, 141, 8, 8, sun);
        }
        rect(c, 297, 144, 30, 33, clay, 12);
        ellipse(c, 295, 139, 34, 15, forest);
        line(c, const Offset(314, 147), const Offset(328, 111), cream, 4);
        note(c, 218, 80, clay);
    }
    star(c, 20, 120, 7, sun);
    star(c, 331, 47, 8, info.color);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _RegionPainter oldDelegate) =>
      oldDelegate.region != region;
}

class TrailConnector extends StatelessWidget {
  const TrailConnector({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    width: double.infinity,
    child: CustomPaint(painter: _TrailPainter()),
  );
}

class _TrailPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFC8CDBA)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var y = 4.0; y < s.height; y += 11) {
      c.drawLine(Offset(s.width / 2, y), Offset(s.width / 2, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
