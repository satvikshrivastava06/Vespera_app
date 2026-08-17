import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: VesperaStyle.background,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile Section
              _buildProfileHeader(),
              const SizedBox(height: 50),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Recents',
                      isSelected: true,
                      iconColor: Colors.greenAccent,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.auto_awesome_rounded,
                      title: "What's new",
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.nights_stay_rounded,
                      title: 'Twilight',
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.queue_music_rounded,
                      title: 'Your playlists',
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite_rounded,
                      title: 'Liked songs',
                    ),
                  ],
                ),
              ),
              
              // Footer Section
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    _buildFooterButton(
                      icon: Icons.cached_rounded,
                      title: 'Switch Account',
                      onTap: () {},
                      showArrow: true,
                    ),
                    const SizedBox(height: 15),
                    _buildFooterButton(
                      icon: Icons.power_settings_new_rounded,
                      title: 'Logout',
                      onTap: () {},
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFCCBC), Color(0xFFFFAB91)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withAlpha(100),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'Alex Rivers',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: VesperaStyle.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Music Enthusiast',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF26A69A),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicContainer(
        height: 65,
        borderRadius: 20,
        backgroundColor: isSelected ? Colors.white : VesperaStyle.background,
        isInset: false,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: VesperaStyle.background,
                    shape: BoxShape.circle,
                    boxShadow: VesperaStyle.neumorphicShadows,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? VesperaStyle.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: VesperaStyle.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool showArrow = false,
  }) {
    return NeumorphicContainer(
      height: 65,
      borderRadius: 20,
      backgroundColor: isLogout ? const Color(0xFFFFF5F5) : Colors.white.withAlpha(150),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.redAccent : VesperaStyle.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isLogout ? Colors.redAccent : VesperaStyle.textPrimary,
                ),
              ),
              if (showArrow) ...[
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: VesperaStyle.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
