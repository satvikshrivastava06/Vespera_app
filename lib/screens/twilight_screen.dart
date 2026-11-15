import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:vespera/models/playable_track.dart';
import 'package:vespera/models/session_models.dart';
import 'package:vespera/models/twilight_models.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/services/session_service.dart';
import 'package:vespera/services/twilight_service.dart';
import 'package:vespera/widgets/skip_reason_sheet.dart';

class TwilightScreen extends StatefulWidget {
  const TwilightScreen({super.key});

  @override
  State<TwilightScreen> createState() => _TwilightScreenState();
}

class _TwilightScreenState extends State<TwilightScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  late Animation<double> _orbPulse;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocus = FocusNode();
  final TwilightService _twilight = TwilightService();
  final SessionService _sessions = SessionService();

  TwilightResponse? _lastResponse;
  SessionState? _activeSession;
  bool _loading = false;
  bool _sessionLoading = false;
  String? _errorMessage;

  // Prevents duplicate submits while a request is in-flight.
  bool get _canSubmit =>
      !_loading && _chatController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _orbPulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );
    _chatController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _orbController.dispose();
    _chatController.dispose();
    _chatFocus.dispose();
    _twilight.dispose();
    super.dispose();
  }

  Future<void> _submit({
    String? prefillText,
    TwilightMode mode = TwilightMode.chat,
  }) async {
    final text = prefillText ?? _chatController.text.trim();
    if (text.isEmpty || _loading) return;
    _chatFocus.unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _lastResponse = null;
    });
    final response = await _twilight.send(text: text, mode: mode);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastResponse = response;
      if (response.status == TwilightStatus.error) {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Something went wrong. Please try again.';
      }
    });
  }

  void _prefillAndSubmit(String text) {
    _chatController.text = text;
    _submit(prefillText: text, mode: TwilightMode.suggestion);
  }

  // ---------------------------------------------------------------------------
  // Unavailable feature stubs (roadmap: show brief message, no new screens)
  // ---------------------------------------------------------------------------

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is not available in this milestone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1535),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050313),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _BgMeshPainter())),
            SafeArea(
              child: Hero(
                tag: 'twilight_interface_transition',
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => _chatFocus.unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24)
                          .copyWith(top: 40, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 28),
                          Center(
                            child: _GlassPill(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Featured',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildOrb(),
                          const SizedBox(height: 16),
                          Text(
                            'Good day!',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How may I assist you today?',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildMoodCard(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildMusicDnaCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildSemanticSearchCard()),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildSuggestions(),
                          const SizedBox(height: 32),
                          _buildChatInput(),
                          // ── Results area ──────────────────────────────────
                          if (_loading) ...[
                            const SizedBox(height: 24),
                            _buildLoadingIndicator(),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 24),
                            _buildErrorBanner(_errorMessage!),
                          ],
                          if (_lastResponse != null &&
                              !_loading &&
                              _errorMessage == null) ...[
                            const SizedBox(height: 24),
                            _buildResults(_lastResponse!),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset('assets/twilight-logo.png',
                width: 36, height: 36, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Text(
              'Twilight AI',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _GlassPill(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Vespera',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Orb
  // ---------------------------------------------------------------------------
  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbPulse,
      builder: (context, child) {
        // Orb pulses faster while a request is loading.
        final intensity = _loading ? 1.0 : _orbPulse.value;
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7850FF).withValues(alpha: 0.55 * intensity),
                blurRadius: 60,
              ),
              BoxShadow(
                color: const Color(0xFF5078FF).withValues(alpha: 0.35 * intensity),
                blurRadius: 120,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset('assets/energy-orb.png',
          width: 280, height: 280, fit: BoxFit.contain),
    );
  }

  // ---------------------------------------------------------------------------
  // Mood card — deferred (roadmap §5: show availability message)
  // ---------------------------------------------------------------------------
  Widget _buildMoodCard() {
    return GestureDetector(
      onTap: () => _showUnavailable('Mood Journey'),
      child: _GlassCardBorder(
        borderRadius: 24,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/aurora-streaks.jpg',
                  fit: BoxFit.cover,
                  color: Colors.white.withValues(alpha: 0.85),
                  colorBlendMode: BlendMode.screen,
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D0A1F).withValues(alpha: 0.95),
                        const Color(0xFF0D0A1F).withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Improve my mood',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 18.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Creates a personalized playlist that starts with 'how you feel' and gently lifts you toward a better mood.",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _ArrowButton(size: 40),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Music DNA card — deferred
  // ---------------------------------------------------------------------------
  Widget _buildMusicDnaCard() {
    return GestureDetector(
      onTap: () => _showUnavailable('Music DNA'),
      child: _GlassCardBorder(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(child: _MusicDnaIcon()),
              ),
              const SizedBox(height: 14),
              Text(
                'Music DNA',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Listening data not available yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  _ArrowButton(size: 34),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Semantic search card — prefills chat input
  // ---------------------------------------------------------------------------
  Widget _buildSemanticSearchCard() {
    return GestureDetector(
      onTap: () {
        _chatController.text = 'Find music that feels like ';
        _chatFocus.requestFocus();
        _chatController.selection = TextSelection.fromPosition(
          TextPosition(offset: _chatController.text.length),
        );
      },
      child: _GlassCardBorder(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(child: _SemanticSearchIcon()),
              ),
              const SizedBox(height: 14),
              Text(
                'Semantic search',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Search music by meaning, not just keywords.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                  _ArrowButton(size: 34),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Suggestion cards — tap prefills input and submits
  // ---------------------------------------------------------------------------
  Widget _buildSuggestions() {
    return Column(
      children: [
        _SuggestionCard(
          text: 'What are the trending songs in India?',
          onTap: () => _prefillAndSubmit('What are the trending songs in India?'),
        ),
        const SizedBox(height: 12),
        _SuggestionCard(
          text: 'I want to hear some rock music from the 90s',
          onTap: () => _prefillAndSubmit('I want to hear some rock music from the 90s'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Chat input
  // ---------------------------------------------------------------------------
  Widget _buildChatInput() {
    return _GlassCardBorder(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 20),
              child: Text(
                'Message Twilight AI…',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              children: [
                // + button — deferred
                GestureDetector(
                  onTap: () => _showUnavailable('Add Context'),
                  child: const _ChatIconBtn(icon: Icons.add),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Stack(
                            children: [
                              Icon(Icons.language_rounded,
                                  color: Colors.white.withValues(alpha: 0.70),
                                  size: 16),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Icon(Icons.search,
                                    color: Colors.white.withValues(alpha: 0.70),
                                    size: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            focusNode: _chatFocus,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Type your request…',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Mic button — deferred
                GestureDetector(
                  onTap: () => _showUnavailable('Voice input'),
                  child: const _ChatIconBtn(icon: Icons.mic_none_rounded),
                ),
                const SizedBox(width: 10),
                // Submit button — live
                GestureDetector(
                  onTap: _canSubmit ? _submit : null,
                  child: AnimatedOpacity(
                    opacity: _canSubmit ? 1.0 : 0.45,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B59FF),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B59FF)
                                .withValues(alpha: _canSubmit ? 0.4 : 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.graphic_eq_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------------

  Widget _buildLoadingIndicator() {
    return _GlassCardBorder(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text(
              'Searching the catalog…',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return _GlassCardBorder(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent.withValues(alpha: 0.85), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(TwilightResponse resp) {
    if (resp.status == TwilightStatus.needsClarification) {
      return _buildInfoBanner(resp.message, Icons.help_outline_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Intent contract summary ──────────────────────────────────────
        if (resp.intentGoal != null) _buildIntentSummary(resp),
        if (resp.tracks.isEmpty) ...[
          const SizedBox(height: 10),
          _buildInfoBanner(resp.message, Icons.search_off_rounded),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
            child: Text(
              resp.message,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
              ),
            ),
          ),
          // ── Start session button ───────────────────────────────────────
          if (_activeSession == null)
            GestureDetector(
              onTap: _sessionLoading ? null : () => _startSession(resp),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B59FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF3B59FF).withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: _sessionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          '▶  Start Session',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            )
          else
            _buildSessionBanner(_activeSession!),
          ...resp.tracks.map((t) => _TrackResultCard(
                track: t,
                onPlay: () => _playTrack(t),
                onSkip: _activeSession != null
                    ? () => _skipWithReason(t.trackId)
                    : null,
              )),
        ],
      ],
    );
  }

  Widget _buildSessionBanner(SessionState s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _GlassCardBorder(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.queue_music_rounded,
                  color: const Color(0xFF3B59FF).withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session active  •  v${s.planVersion}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${s.queue.length} tracks  •  ${s.plannedDuration}  •  '
                      '${(s.instrumentalPct * 100).toStringAsFixed(0)}% instrumental',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.5,
                      ),
                    ),
                    if (!s.quotaSatisfied && s.unsatisfiedNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⚠ ${s.unsatisfiedNote}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.orangeAccent.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
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

  Widget _buildIntentSummary(TwilightResponse resp) {
    final chips = <_IntentChip>[];

    if (resp.intentGoal != null) {
      chips.add(_IntentChip(label: resp.intentGoal!, icon: Icons.track_changes_rounded));
    }
    if (resp.intentEnergy != null && resp.intentEnergy != 'any') {
      final icon = resp.intentEnergy == 'high'
          ? Icons.bolt_rounded
          : Icons.nights_stay_rounded;
      chips.add(_IntentChip(label: resp.intentEnergy!, icon: icon, dim: true));
    }
    if (resp.intentDurationMin != null) {
      chips.add(_IntentChip(
          label: '${resp.intentDurationMin} min',
          icon: Icons.timer_outlined,
          dim: true));
    }
    if (resp.intentRequireInstrumental == true) {
      chips.add(
          const _IntentChip(label: 'instrumental', icon: Icons.piano_rounded, dim: true));
    }
    for (final neg in resp.intentNegations.take(3)) {
      chips.add(_IntentChip(
          label: neg, icon: Icons.block_rounded, dim: true, negative: true));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _GlassCardBorder(
        borderRadius: 14,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message, IconData icon) {
    return _GlassCardBorder(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Session actions
  // ---------------------------------------------------------------------------

  Future<void> _startSession(TwilightResponse resp) async {
    if (_sessionLoading) return;
    setState(() => _sessionLoading = true);
    final trackIds = resp.tracks
        .where((t) => t.sessionEligible)
        .take(5)
        .map((t) => t.trackId)
        .toList();
    final session = await _sessions.createSession(
      text: resp.intentGoal ?? _chatController.text,
      seedTrackIds: trackIds,
    );
    if (!mounted) return;
    setState(() {
      _sessionLoading = false;
      _activeSession = session;
    });
    if (session != null && session.queue.isNotEmpty) {
      final audio = AudioPlayerService();
      final tracks = session.queue
          .where((q) => q.audioUrl != null && q.audioUrl!.isNotEmpty)
          .map((q) => q.toPlayableTrack())
          .toList();
      if (tracks.isNotEmpty) await audio.loadQueue(tracks);
    }
  }

  Future<void> _skipWithReason(String trackId) async {
    final session = _activeSession;
    if (session == null) return;
    if (!mounted) return;
    final reason = await showSkipReasonSheet(context);
    if (reason == null || !mounted) return;
    final fb = await _sessions.submitFeedback(
      sessionId: session.sessionId,
      trackId: trackId,
      reason: reason,
    );
    if (!mounted) return;
    if (fb != null && fb.replanned) {
      final newState = await _sessions.getSession(session.sessionId);
      if (!mounted) return;
      setState(() => _activeSession = newState ?? _activeSession);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Queue updated (v${fb.planVersion}) — session scope only.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1535),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _playTrack(TwilightTrackResult t) {
    final audio = AudioPlayerService();
    if (t.sessionEligible && t.audioUrl != null && t.audioUrl!.isNotEmpty) {
      audio.playTrack(PlayableTrack(
        id: t.trackId,
        title: t.title,
        artist: t.artist,
        audioUrl: t.audioUrl,
        imageUrl: t.imageUrl,
        jamendoShareUrl: t.jamendoShareUrl,
        playableMs: t.playableMs,
        sessionEligible: true,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No licensed stream for "${t.title}".',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1535),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Track result card
// ══════════════════════════════════════════════════════════════════════════════

class _TrackResultCard extends StatelessWidget {
  const _TrackResultCard({required this.track, required this.onPlay, this.onSkip});
  final TwilightTrackResult track;
  final VoidCallback onPlay;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCardBorder(
        borderRadius: 16,
        child: InkWell(
          onTap: onPlay,
          onLongPress: onSkip,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                      ? Image.network(track.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => _placeholderThumb())
                      : _placeholderThumb(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        track.artist,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Play / handoff indicator
                Icon(
                  track.sessionEligible
                      ? Icons.play_circle_fill_rounded
                      : Icons.open_in_new_rounded,
                  color: track.sessionEligible
                      ? const Color(0xFF3B59FF)
                      : Colors.white.withValues(alpha: 0.4),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Icon(Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.3), size: 22),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable visual components (unchanged from original)
// ══════════════════════════════════════════════════════════════════════════════

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.08),
                  offset: const Offset(0, 1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCardBorder extends StatelessWidget {
  const _GlassCardBorder({required this.child, this.borderRadius = 24});
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: CustomPaint(
          painter: _GlassBorderPainter(radius: borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0A1F).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.8],
      ).createShader(rect);
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Icon(Icons.arrow_outward_rounded,
            color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _ChatIconBtn extends StatelessWidget {
  const _ChatIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
          child: Icon(icon,
              color: Colors.white.withValues(alpha: 0.8), size: 20)),
    );
  }
}

class _MusicDnaIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(22, 22), painter: _MusicDnaPainter());
}

class _MusicDnaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.375, size.height * 0.291),
        size.width * 0.133, p);
    final path = Path()
      ..moveTo(size.width * 0.145, size.height * 0.812)
      ..quadraticBezierTo(size.width * 0.145, size.height * 0.575,
          size.width * 0.375, size.height * 0.575)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.575,
          size.width * 0.6, size.height * 0.812)
      ..close();
    canvas.drawPath(path, p);
    final path2 = Path()
      ..moveTo(size.width * 0.56, size.height * 0.812)
      ..lineTo(size.width * 0.74, size.height * 0.55)
      ..lineTo(size.width * 0.93, size.height * 0.812)
      ..close();
    canvas.drawPath(path2, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SemanticSearchIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(22, 22), painter: _SemanticSearchPainter());
}

class _SemanticSearchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final dark = Paint()
      ..color = const Color(0xFF0E0B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.125, size.height * 0.166,
            size.width * 0.58, size.height * 0.583),
        const Radius.circular(1.5));
    canvas.drawRRect(rect, white);
    canvas.drawLine(Offset(size.width * 0.125, size.height * 0.33),
        Offset(size.width * 0.705, size.height * 0.33), dark);
    for (var x in [0.29, 0.46, 0.625]) {
      canvas.drawLine(Offset(size.width * x, size.height * 0.166),
          Offset(size.width * x, size.height * 0.33), dark);
    }
    final penPath = Path()
      ..moveTo(size.width * 0.583, size.height * 0.833)
      ..lineTo(size.width * 0.833, size.height * 0.583)
      ..lineTo(size.width * 0.916, size.height * 0.666)
      ..lineTo(size.width * 0.666, size.height * 0.916)
      ..lineTo(size.width * 0.583, size.height * 0.916)
      ..close();
    canvas.drawPath(penPath, white);
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.666),
        Offset(size.width * 0.833, size.height * 0.75), dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BgMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawGlow(canvas, size, Offset(size.width * 0.2, size.height * 0.1),
        const Color(0xFF503CB4), 0.25);
    _drawGlow(canvas, size, Offset(size.width * 0.9, size.height * 0.9),
        const Color(0xFF7828C8), 0.18);
    _drawGlow(canvas, size, Offset(size.width * 0.5, size.height * 0.5),
        const Color(0xFF1E1450), 0.40);
  }

  void _drawGlow(Canvas canvas, Size size, Offset center, Color color,
      double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
              colors: [color.withValues(alpha: alpha), Colors.transparent])
          .createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.8));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// Intent chip
// ══════════════════════════════════════════════════════════════════════════════

class _IntentChip extends StatelessWidget {
  const _IntentChip({
    required this.label,
    required this.icon,
    this.dim = false,
    this.negative = false,
  });
  final String label;
  final IconData icon;
  final bool dim;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final baseColor = negative
        ? const Color(0xFFFF4444)
        : const Color(0xFF3B59FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: dim ? 0.08 : 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: baseColor.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: dim ? 0.7 : 0.9),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {  final String text;
  final VoidCallback onTap;
  const _SuggestionCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassCardBorder(
        borderRadius: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
