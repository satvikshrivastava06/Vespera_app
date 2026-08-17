import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/screens/view_all_screen.dart';

class VesperaStyle {
  // Background & Core Colors
  static const Color background = Color(0xFFE0E5EC); // Real neumorphic mid-tone grey-blue for high contrast white pop
  static const Color accent = Color(0xFFFF7043); // Orange-red for VIEW ALL
  static const Color textPrimary = Color(0xFF202329); // Near black for bold headings
  static const Color textSecondary = Color(0xFF869AB8); // Soft grey-blue for subtitles
  static const Color cyanText = Color(0xFF29B6F6); // Cyan for '120 SONGS'
  static const Color neonGreen = Color(0xFF00E676); // Green for borders/icons
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color neonBlue = Color(0xFF00B0FF);
  static const Color greenTag = Color(0xFF43A047); 
  static const Color blueTag = Color(0xFF1E88E5); 

  // Shadow definitions
  static List<BoxShadow> get neumorphicShadows {
    return [
      const BoxShadow(
        color: Colors.white,
        offset: Offset(-8, -8),
        blurRadius: 16,
        spreadRadius: 0,
      ),
      const BoxShadow(
        color: Color(0xFFD3DAE8),
        offset: Offset(8, 8),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> get insetShadows {
    return [
      BoxShadow(
        color: const Color(0xFFD3DAE8).withAlpha(180),
        offset: const Offset(4, 4),
        blurRadius: 8,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: Colors.white.withAlpha(200),
        offset: const Offset(-4, -4),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ];
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final bool isInset;
  final BoxShape shape;
  final Color? backgroundColor;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 25,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.isInset = false,
    this.shape = BoxShape.rectangle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? VesperaStyle.background,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        boxShadow: isInset ? VesperaStyle.insetShadows : VesperaStyle.neumorphicShadows,
      ),
      child: child,
    );
  }
}

class ViewAllButton extends StatefulWidget {
  final String title;
  final List<CategoryItem>? items;

  const ViewAllButton({
    super.key,
    required this.title,
    this.items,
  });

  @override
  State<ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<ViewAllButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  double _rotationTurns = 0.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          // Allow the 800ms rotation animation to complete before navigating
          await Future.delayed(const Duration(milliseconds: 800));
          if (!context.mounted) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewAllScreen(
                title: widget.title,
                items: widget.items ?? [],
              ),
            ),
          );
        },
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
            _rotationTurns -= 1.0; 
          });
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: SizedBox(
          width: 100,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow Blur Effect
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.95,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFC00FF).withAlpha(_isHovered ? 100 : 50),
                          blurRadius: _isHovered ? 30 : 15,
                          spreadRadius: _isHovered ? 5 : 0,
                          offset: const Offset(-2, -2),
                        ),
                        BoxShadow(
                          color: const Color(0xFF00DBDE).withAlpha(_isHovered ? 100 : 50),
                          blurRadius: _isHovered ? 30 : 15,
                          spreadRadius: _isHovered ? 5 : 0,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Gradient Border
              Positioned(
                left: -3,
                top: -3,
                right: -3,
                bottom: -3,
                child: AnimatedScale(
                  scale: _isPressed ? 0.8 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedRotation(
                    turns: _rotationTurns,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutExpo,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE81CFF), Color(0xFF40C9FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main Button Area (Glassmorphism background)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'View all',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class SectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  final List<CategoryItem>? items;

  const SectionHeader({
    super.key, 
    required this.title,
    this.showViewAll = true,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: VesperaStyle.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (showViewAll) ViewAllButton(title: title, items: items),
      ],
    );
  }
}

