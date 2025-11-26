import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectDetailsAppBar extends StatelessWidget {
  final Project project;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShowOptions;
  final VoidCallback onShowStatistics;

  const ProjectDetailsAppBar({
    super.key,
    required this.project,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onShowOptions,
    required this.onShowStatistics,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: onBack,
        icon: _circleButton(
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: onToggleBookmark,
          icon: _circleButton(
            child: Icon(
              project.isBookmark ? Icons.bookmark : Icons.bookmark_border,
              color: project.isBookmark ? Colors.amber : Colors.black87,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: onShowOptions,
          icon: _circleButton(
            child: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _AppBarBackground(
          project: project,
          onShowStats: onShowStatistics,
        ),
      ),
    );
  }

  Widget _circleButton({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  final Project project;
  final VoidCallback onShowStats;

  const _AppBarBackground({
    required this.project,
    required this.onShowStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
            Color(0xFF81C784),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _CirclePatternPainter()),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          project.projectName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: onShowStats,
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Statistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white70,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  const _CirclePatternPainter({this.opacity = 0.12});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final ring = Paint()
      ..color = Colors.white.withOpacity(opacity + 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    void circle(double x, double y, double r) {
      final c = Offset(size.width * x, size.height * y);
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r + 8, ring);
    }

    circle(0.18, 0.30, 60);
    circle(0.82, 0.58, 80);
    circle(0.48, 0.80, 40);
    circle(0.90, 0.22, 50);
    circle(0.10, 0.85, 30);
    circle(0.34, 0.60, 24);

    final dot = Paint()
      ..color = Colors.white.withOpacity(opacity + 0.05)
      ..style = PaintingStyle.fill;
    for (double t = 0; t <= 1.0; t += 0.08) {
      final p = Offset(size.width * t, size.height * (0.18 + 0.5 * t));
      canvas.drawCircle(p, 2.2, dot);
    }

    canvas.restore();

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.2),
        radius: 1.2,
        colors: [
          Colors.white.withOpacity(0.00),
          Colors.white.withOpacity(0.06),
        ],
        stops: const [0.75, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
