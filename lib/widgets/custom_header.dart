import 'package:flutter/material.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/screens/search_screen.dart';

class CustomHeader extends StatelessWidget {
  final String? greeting;
  const CustomHeader({super.key, this.greeting});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: VesperaStyle.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      forceMaterialTransparency: true,
      toolbarHeight: 100,
      expandedHeight: greeting != null ? 120 : null,
      leadingWidth: 80,
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(top: 40, left: 20),
          child: NeumorphicContainer(
            width: 54,
            height: 54,
            shape: BoxShape.circle,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                borderRadius: BorderRadius.circular(27),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: VesperaStyle.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: VesperaStyle.neonGreen,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: VesperaStyle.neonGreen.withAlpha(150),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: VesperaStyle.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'Vespera',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Stewart Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7209B7),
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Colors.white.withAlpha(80),
                          offset: const Offset(-0.5, -0.5),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: const Color(0xFF7209B7).withAlpha(100),
                          offset: const Offset(1, 1),
                          blurRadius: 1,
                        ),
                        Shadow(
                          color: const Color(0xFF7209B7).withAlpha(80),
                          offset: const Offset(2, 2),
                          blurRadius: 1.5,
                        ),
                        Shadow(
                          color: Colors.black.withAlpha(150),
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: Colors.black.withAlpha(40),
                          offset: const Offset(8, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 40),
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: NeumorphicContainer(
                width: 54,
                height: 54,
                shape: BoxShape.circle,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: VesperaStyle.neonGreen.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded, 
                      color: VesperaStyle.neonGreen, 
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
