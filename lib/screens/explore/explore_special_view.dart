import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreSpecialView extends StatefulWidget {
  final VoidCallback onSwitchView;

  const ExploreSpecialView({super.key, required this.onSwitchView});

  @override
  State<ExploreSpecialView> createState() => _ExploreSpecialViewState();
}

class _ExploreSpecialViewState extends State<ExploreSpecialView> {
  static const double _itemExtent = 152;
  static const double _playPillWidth = 268;
  static const double _playPillAnchorWidth = 214;
  static const double _playPillHeight = 80;
  static const double _selectedDiscSize = 82;
  static const double _arcDiscSize = 78;
  static const double _discOverlapIntoPill = 30;
  static const double _arcDiscLeftShift = -38;

  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: 3);
  int _selectedIndex = 3;

  final List<SongInfo> _songs = [
    SongInfo(
      title: 'Forgotten',
      artist: 'Nyven_Shane',
      image: 'https://picsum.photos/seed/forgotten/500/500',
    ),
    SongInfo(
      title: 'Dreams',
      artist: 'Miles_Esther',
      image: 'https://picsum.photos/seed/dreams/500/500',
    ),
    SongInfo(
      title: 'Horizon',
      artist: 'Krishin',
      image: 'https://picsum.photos/seed/horizon/500/500',
    ),
    SongInfo(
      title: 'Day light',
      artist: 'Kernin Joki',
      image: 'https://picsum.photos/seed/daylight/500/500',
    ),
    SongInfo(
      title: 'Cassette',
      artist: 'Black, Marvin',
      image: 'https://picsum.photos/seed/cassette/500/500',
    ),
    SongInfo(
      title: 'Crimson',
      artist: 'Henry, Arthur',
      image: 'https://picsum.photos/seed/crimson/500/500',
    ),
    SongInfo(
      title: 'Phantom',
      artist: 'Prince, Juancho',
      image: 'https://picsum.photos/seed/phantom/500/500',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                      letterSpacing: -1.2,
                    ),
                  ),
                  Row(
                    children: [
                      _ViewSwitchButton(onTap: widget.onSwitchView),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.more_horiz_rounded,
                        size: 24,
                        color: Color(0xFF111827),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double pillLeft =
                      (constraints.maxWidth - _playPillAnchorWidth) / 2;
                  final double discLeft =
                      pillLeft - _selectedDiscSize + _discOverlapIntoPill;
                  final double wheelLeft = discLeft;
                  final double pillTop =
                      (constraints.maxHeight - _playPillHeight) / 2 + 6;
                  final double discTop =
                      (constraints.maxHeight - _selectedDiscSize) / 2 + 6;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: wheelLeft,
                        top: -18,
                        bottom: -18,
                        width: constraints.maxWidth - wheelLeft + 40,
                        child: ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: _itemExtent,
                          physics: const FixedExtentScrollPhysics(),
                          renderChildrenOutsideViewport: true,
                          clipBehavior: Clip.none,
                          diameterRatio: 2.8,
                          perspective: 0.0022,
                          offAxisFraction: -1.05,
                          squeeze: 1.05,
                          overAndUnderCenterOpacity: 1.0,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _songs.length,
                            builder: (context, index) {
                              return _ArcSongItem(
                                controller: _scrollController,
                                itemExtent: _itemExtent,
                                index: index,
                                song: _songs[index],
                                isSelected: _selectedIndex == index,
                                discLeftShift: _arcDiscLeftShift,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: pillLeft,
                        top: pillTop,
                        width: _playPillWidth,
                        height: _playPillHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFEAEFF5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF111827)
                                    .withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 54),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _songs[_selectedIndex].title,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF111827),
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _songs[_selectedIndex].artist,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9AA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 38,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F5FA),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFDDE3ED),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Play',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: discLeft,
                        top: discTop,
                        child: IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            child: Container(
                              key: ValueKey<String>(
                                  _songs[_selectedIndex].image),
                              width: _selectedDiscSize,
                              height: _selectedDiscSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(
                                      _songs[_selectedIndex].image),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                    color: Colors.white, width: 4.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 22,
                                    offset: const Offset(6, 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              height: 78,
              margin:
                  const EdgeInsets.only(left: 36, right: 36, bottom: 38, top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 46),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _buildNavItem(Icons.home_rounded, false),
                  ),
                  _buildNavItem(Icons.nature, true),
                  _buildNavItem(Icons.bookmark_rounded, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 30,
          color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _ViewSwitchButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewSwitchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.grid_view_rounded,
          size: 20,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _ArcSongItem extends StatelessWidget {
  final FixedExtentScrollController controller;
  final double itemExtent;
  final int index;
  final SongInfo song;
  final bool isSelected;
  final double discLeftShift;

  const _ArcSongItem({
    required this.controller,
    required this.itemExtent,
    required this.index,
    required this.song,
    required this.isSelected,
    required this.discLeftShift,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (isSelected) {
          return const SizedBox.shrink();
        }

        final double currentIndex = controller.hasClients
            ? controller.offset / itemExtent
            : controller.initialItem.toDouble();
        final double delta = index - currentIndex;
        final double t = delta.clamp(-2.2, 2.2);
        final double textAngle = (-t) * 0.28;
        const double discSize = _ExploreSpecialViewState._arcDiscSize;

        return Transform.translate(
          offset: Offset(discLeftShift, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: discSize,
                height: discSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(song.image),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(6, 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Transform.rotate(
                angle: textAngle,
                child: SizedBox(
                  width: 165,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 37 / 2.1,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF616A76),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA2AAB6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SongInfo {
  final String title;
  final String artist;
  final String image;

  SongInfo({required this.title, required this.artist, required this.image});
}
