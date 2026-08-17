import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vespera/models/home_feed.dart';
import 'package:vespera/services/api_service.dart';
import 'package:vespera/widgets/search_widgets.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF080B1E),
      body: _SearchBackground(),
    );
  }
}

// ─── Animated background shell ────────────────────────────────────────────────
class _SearchBackground extends StatefulWidget {
  const _SearchBackground();

  @override
  State<_SearchBackground> createState() => _SearchBackgroundState();
}

class _SearchBackgroundState extends State<_SearchBackground>
    with TickerProviderStateMixin {
  late final AnimationController _nebula;
  late final AnimationController _stars;

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PlaylistItem> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nebula = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _stars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _nebula.dispose();
    _stars.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length > 1) {
        _performSearch(query);
      } else if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _lastQuery = "";
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastQuery && query.isNotEmpty) return;
    
    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    try {
      final results = await _apiService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _isLoading || _searchResults.isNotEmpty || _searchController.text.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Deep-space base gradient ──────────────────────────────────
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF080B1E),
                Color(0xFF0F1232),
                Color(0xFF140D30),
                Color(0xFF0A0F26),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),

        // ── 2. Static star field ─────────────────────────────────────────
        CustomPaint(painter: _StarFieldPainter()),

        // ── 3. Pulsing nebula orbs ────────────────────────────────────────
        AnimatedBuilder(
          animation: _nebula,
          builder: (_, __) {
            final t = _nebula.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                _nebulaOrb(dx: -80,  dy: -100, size: 320 + 30 * t,       color: const Color(0xFF8B5CF6), peak: 0.28 + 0.07 * t),
                _nebulaOrb(dx: 220,  dy: 160,  size: 290 + 40 * (1 - t), color: const Color(0xFF3B82F6), peak: 0.20 + 0.06 * (1 - t)),
                _nebulaOrb(dx: 170,  dy: 500,  size: 260 + 35 * t,       color: const Color(0xFFEC4899), peak: 0.16 + 0.06 * t),
                _nebulaOrb(dx: -60,  dy: 650,  size: 220 + 25 * (1 - t), color: const Color(0xFF00E676), peak: 0.10 + 0.04 * (1 - t)),
                _nebulaOrb(dx: 100,  dy: 310,  size: 180 + 20 * t,       color: const Color(0xFF06B6D4), peak: 0.12 + 0.04 * t),
              ],
            );
          },
        ),

        // ── 5. Shooting stars (full-screen coverage) ─────────────────────
        AnimatedBuilder(
          animation: _stars,
          builder: (_, __) => CustomPaint(
            painter: _ShootingStarsPainter(_stars.value),
          ),
        ),

        // ── 6. Foreground content ─────────────────────────────────────────
        SafeArea(
          child: Stack(
            children: [
              // Default Content (Dimmed when searching)
              Opacity(
                opacity: isSearching ? 0.2 : 1.0,
                child: IgnorePointer(
                  ignoring: isSearching,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const SearchHeader(),
                        const SizedBox(height: 35),
                        SearchInputField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: _performSearch,
                        ),
                        const SizedBox(height: 45),

                        const DarkSectionTitle(title: 'Quick Search'),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: const [
                              SquareAlbumCard(imageUrl: 'https://picsum.photos/seed/album1/300/300'),
                              SizedBox(width: 15),
                              SquareAlbumCard(imageUrl: 'https://picsum.photos/seed/album2/300/300'),
                              SizedBox(width: 15),
                              SquareAlbumCard(imageUrl: 'https://picsum.photos/seed/album3/300/300'),
                              SizedBox(width: 15),
                              SquareAlbumCard(imageUrl: 'https://picsum.photos/seed/album4/300/300'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        const DarkSectionTitle(title: 'Trending'),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: const [
                              VerticalTrendingCard(imageUrl: 'https://picsum.photos/seed/trend5/400/400'),
                              SizedBox(width: 15),
                              VerticalTrendingCard(imageUrl: 'https://picsum.photos/seed/trend6/400/400'),
                              SizedBox(width: 15),
                              VerticalTrendingCard(imageUrl: 'https://picsum.photos/seed/trend7/400/400'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Results Glass Overlay
              if (isSearching)
                _buildResultsLayer(),

              // Persistent Search Bar on top
              if (isSearching)
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 95),
                      SearchInputField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _performSearch,
                      ),
                    ],
                  ),
                ),

              const Positioned(
                left: 0, right: 0, bottom: 0,
                child: DarkGlassNavBar(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsLayer() {
    return Positioned.fill(
      top: 160,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withAlpha(160),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(child: Text("No results found", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return RecentSongTile(
                          imageUrl: item.imageUrl,
                          title: item.title,
                          duration: item.subtitle,
                        );
                      },
                    ),
          ),
        ),
      ),
    );
  }

  static Widget _nebulaOrb({
    required double dx, required double dy,
    required double size, required Color color, required double peak,
  }) {
    return Positioned(
      left: dx, top: dy,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withAlpha((peak * 255).toInt()),
            color.withAlpha((peak * 0.38 * 255).toInt()),
            color.withAlpha(0),
          ], stops: const [0.0, 0.45, 1.0]),
        ),
      ),
    );
  }
}

// ─── Static star field ────────────────────────────────────────────────────────
class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 130; i++) {
      final x = ((i * 173 + 37) % 997) / 997.0 * size.width;
      final y = ((i * 293 + 61) % 991) / 991.0 * size.height;
      final r = i % 13 == 0 ? 1.8 : (i % 5 == 0 ? 1.1 : 0.65);
      final a = 0.10 + (i % 10) * 0.07;
      paint.color = (i % 19 == 0)
          ? const Color(0xFFC4B5FD).withAlpha((a.clamp(0, 0.85) * 255).toInt())
          : (i % 7 == 0)
              ? const Color(0xFF93C5FD).withAlpha((a.clamp(0, 0.65) * 255).toInt())
              : Colors.white.withAlpha((a.clamp(0, 0.70) * 255).toInt());
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Shooting stars ──────────────────────────────────────────────────────────
class _ShootingStarsPainter extends CustomPainter {
  final double t;
  _ShootingStarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawStar(canvas, size,
      ws: 0.00, we: 0.22,
      x0: w * 0.08, y0: h * 0.04, x1: w * 0.58, y1: h * 0.20,
      tail: w * 0.26, color: const Color(0xFFDDD6FE));

    _drawStar(canvas, size,
      ws: 0.38, we: 0.58,
      x0: w * 0.40, y0: h * 0.02, x1: w * 0.90, y1: h * 0.17,
      tail: w * 0.20, color: const Color(0xFFBAE6FD));

    _drawStar(canvas, size,
      ws: 0.70, we: 0.90,
      x0: w * 0.03, y0: h * 0.12, x1: w * 0.48, y1: h * 0.30,
      tail: w * 0.24, color: Colors.white);

    _drawStar(canvas, size,
      ws: 0.12, we: 0.32,
      x0: w * 0.20, y0: h * 0.58, x1: w * 0.78, y1: h * 0.74,
      tail: w * 0.26, color: const Color(0xFFA5F3FC));

    _drawStar(canvas, size,
      ws: 0.48, we: 0.66,
      x0: w * 0.05, y0: h * 0.76, x1: w * 0.60, y1: h * 0.90,
      tail: w * 0.22, color: const Color(0xFFF9A8D4));

    _drawStar(canvas, size,
      ws: 0.78, we: 0.96,
      x0: w * 0.30, y0: h * 0.64, x1: w * 0.88, y1: h * 0.82,
      tail: w * 0.24, color: const Color(0xFFD9F99D));
  }

  void _drawStar(Canvas canvas, Size size, {
    required double ws, required double we,
    required double x0, required double y0,
    required double x1, required double y1,
    required double tail, required Color color,
  }) {
    if (t < ws || t > we) return;
    final p = (t - ws) / (we - ws);
    final ease = p < 0.5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;
    final double alpha;
    if (p < 0.15) {
      alpha = p / 0.15;
    } else if (p > 0.80) {
      alpha = 1.0 - (p - 0.80) / 0.20;
    } else {
      alpha = 1.0;
    }
    if (alpha <= 0) return;

    final hx = x0 + (x1 - x0) * ease;
    final hy = y0 + (y1 - y0) * ease;
    final dx = x1 - x0;
    final dy = y1 - y0;
    final dist = math.sqrt(dx * dx + dy * dy);
    final ndx = dx / dist;
    final ndy = dy / dist;
    final tx = hx - ndx * tail;
    final ty = hy - ndy * tail;

    canvas.drawLine(
      Offset(tx, ty), Offset(hx, hy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            color.withAlpha(0),
            color.withAlpha((alpha * 0.50 * 255).toInt()),
            color.withAlpha((alpha * 0.95 * 255).toInt()),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromPoints(Offset(tx, ty), Offset(hx, hy))),
    );

    canvas.drawCircle(
      Offset(hx, hy), 3.8,
      Paint()
        ..color = color.withAlpha((alpha * 0.40 * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      Offset(hx, hy), 1.2,
      Paint()..color = Colors.white.withAlpha((alpha * 255).toInt()),
    );
  }

  @override
  bool shouldRepaint(covariant _ShootingStarsPainter old) => old.t != t;
}
