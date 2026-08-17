import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/screens/search_screen.dart';
import 'package:vespera/screens/profile_screen.dart';
import 'package:vespera/widgets/floating_bottom_nav.dart';
import 'package:vespera/services/api_service.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/models/home_feed.dart';

class ExploreMainView extends StatefulWidget {
  final VoidCallback onSwitchView;
  final VoidCallback onGoHome;

  const ExploreMainView({
    super.key,
    required this.onSwitchView,
    required this.onGoHome,
  });

  @override
  State<ExploreMainView> createState() => _ExploreMainViewState();
}

class _ExploreMainViewState extends State<ExploreMainView> {
  final ApiService _apiService = ApiService();
  final AudioPlayerService _audioService = AudioPlayerService();
  ExploreFeedResponse? _exploreData;
  int _selectedChip = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExploreData();
  }

  Future<void> _loadExploreData() async {
    try {
      final data = await _apiService.fetchExploreFeed();
      if (mounted) {
        setState(() {
          _exploreData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const Color _chipInactive = Color(0xFF2A2D4A);
  static const Color _muted = Color(0xFF9CA3C7);

  List<String> get _chips => _exploreData?.categories ?? ['All', 'Rock', 'Hip-Hop', 'Pop'];

  List<PlaylistItem> get _events => _exploreData?.trendingEvents ?? [];
  List<PlaylistItem> get _mixes => _exploreData?.personalizedMixes ?? [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _CosmicBackground()),
        SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 34),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Top live events'),
                        const SizedBox(height: 18),
                        _buildLiveEventsRow(),
                        const SizedBox(height: 30),
                        _sectionTitle('You may like'),
                        const SizedBox(height: 16),
                        _buildFilterChips(),
                        const SizedBox(height: 16),
                        _buildMasonryGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FloatingBottomNav(
            active: FloatingNavActive.home,
            onHomeTap: widget.onGoHome,
            onExploreGridTap: widget.onSwitchView,
            onSearchTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            onProfileTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildLiveEventsRow() {
    if (_events.isEmpty && !_isLoading) return const SizedBox.shrink();
    
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _isLoading ? 4 : _events.length,
        separatorBuilder: (_, index) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          if (_isLoading) return _buildShimmerEvent();
          final event = _events[index];
          return GestureDetector(
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Playing Live Event: ${event.title}")),
              );
              _audioService.playFromSearch(event.searchQuery, event.title);
            },
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFFF6B9D),
                          Color(0xFFC850C0),
                          Color(0xFF4158D0),
                          Color(0xFFFF6B9D),
                        ],
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerEvent() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedChip == index;
          final label = index == _chips.length - 1 ? 'Class...' : _chips[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : _chipInactive.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.black : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasonryGrid() {
    if (_mixes.isEmpty && !_isLoading) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final colWidth = (constraints.maxWidth - gap) / 2;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SliverColumn(
              width: colWidth,
              items: _mixes.asMap().entries.where((e) => e.key % 2 == 0).map((e) => e.value).toList(),
              colWidth: colWidth,
              gap: gap,
              audioService: _audioService,
            ),
            const SizedBox(width: gap),
            SliverColumn(
              width: colWidth,
              items: _mixes.asMap().entries.where((e) => e.key % 2 != 0).map((e) => e.value).toList(),
              colWidth: colWidth,
              gap: gap,
              audioService: _audioService,
            ),
          ],
        );
      },
    );
  }
}

class SliverColumn extends StatelessWidget {
  final List<PlaylistItem> items;
  final double colWidth;
  final double gap;
  final AudioPlayerService audioService;
  final double width;

  const SliverColumn({
    super.key,
    required this.items,
    required this.colWidth,
    required this.gap,
    required this.audioService,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: items.map((item) {
          final isLong = (items.indexOf(item) % 3 == 0);
          return Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: GestureDetector(
              onTap: () => audioService.playFromSearch(item.searchQuery, item.title),
              child: Container(
                width: colWidth,
                height: colWidth * (isLong ? 1.4 : 0.9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(150)],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    item.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Deep-space gradient with soft nebula glows and a star field.
class _CosmicBackground extends StatelessWidget {
  const _CosmicBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0E24),
            Color(0xFF151B3D),
            Color(0xFF1A1040),
            Color(0xFF0D1228),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _nebulaOrb(280, const Color(0xFF8B5CF6), 0.28),
          ),
          Positioned(
            top: 220,
            left: -110,
            child: _nebulaOrb(300, const Color(0xFF3B82F6), 0.22),
          ),
          Positioned(
            bottom: 160,
            right: -50,
            child: _nebulaOrb(240, const Color(0xFFEC4899), 0.2),
          ),
          Positioned(
            bottom: -40,
            left: 40,
            child: _nebulaOrb(200, const Color(0xFF6366F1), 0.14),
          ),
          CustomPaint(painter: _StarFieldPainter()),
        ],
      ),
    );
  }

  Widget _nebulaOrb(double size, Color color, double peakOpacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: peakOpacity),
            color.withValues(alpha: peakOpacity * 0.35),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var i = 0; i < 95; i++) {
      final x = ((i * 127 + 41) % 997) / 997.0 * size.width;
      final y = ((i * 311 + 73) % 991) / 991.0 * size.height;
      final radius = i % 11 == 0 ? 1.6 : (i % 4 == 0 ? 1.1 : 0.65);
      final alpha = 0.12 + (i % 9) * 0.07;

      paint.color = (i % 17 == 0)
          ? const Color(0xFFC4B5FD).withValues(alpha: alpha.clamp(0.0, 0.75))
          : Colors.white.withValues(alpha: alpha.clamp(0.0, 0.65));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
