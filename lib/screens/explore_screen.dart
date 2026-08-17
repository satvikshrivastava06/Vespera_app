import 'package:flutter/material.dart';
import 'package:vespera/screens/explore/explore_main_view.dart';
import 'package:vespera/screens/explore/explore_special_view.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _showMainView = false;

  void _openMainView() => setState(() => _showMainView = true);

  void _openSpecialView() => setState(() => _showMainView = false);

  void _goHome() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _showMainView ? const Color(0xFF0B0E24) : const Color(0xFFF4F7FB),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          final scale = Tween<double>(begin: 0.97, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: _showMainView
            ? ExploreMainView(
                key: const ValueKey('explore_main'),
                onSwitchView: _openSpecialView,
                onGoHome: _goHome,
              )
            : ExploreSpecialView(
                key: const ValueKey('explore_special'),
                onSwitchView: _openMainView,
              ),
      ),
    );
  }
}
