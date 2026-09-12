import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turnable_page/turnable_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TurnablePdf.initPDFLoaders();
  runApp(const TurnableTestApp());
}

class TurnableTestApp extends StatelessWidget {
  const TurnableTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turnable Page — Test Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D5AFE),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN — selector between Widget Book and PDF Book
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // ── Header ──────────────────────────────────────────────────────
            const Icon(Icons.auto_stories, size: 72, color: Color(0xFF3D5AFE)),
            const SizedBox(height: 16),
            const Text(
              'Turnable Page',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Integration Test Suite',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 60),

            // ── Mode Cards ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ModeCard(
                      icon: Icons.widgets_rounded,
                      title: 'Widget Book',
                      subtitle:
                          'Test page-flip with Flutter widgets\n'
                          '(text, buttons, images, scrollable content)',
                      accentColor: const Color(0xFF00E5FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WidgetBookScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ModeCard(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'PDF Book',
                      subtitle:
                          'Test page-flip with a real PDF document\n'
                          '(asset PDF or network URL)',
                      accentColor: const Color(0xFFFF6D00),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PdfPickerScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Version badge ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'turnable_page v1.0.2',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET BOOK SCREEN — tests Issue #5 (CachedImage-like), #4 (Stack+Scroll)
// ─────────────────────────────────────────────────────────────────────────────

class WidgetBookScreen extends StatefulWidget {
  const WidgetBookScreen({super.key});

  @override
  State<WidgetBookScreen> createState() => _WidgetBookScreenState();
}

class _WidgetBookScreenState extends State<WidgetBookScreen> {
  final PageFlipController _controller = PageFlipController();
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  // Different page "types" to stress-test compositing scenarios
  static const List<_PageConfig> _pages = [
    _PageConfig(
      label: 'Page 1',
      type: _PageType.gradient,
      color: Color(0xFF3D5AFE),
      description: 'Basic gradient page\n(baseline render test)',
    ),
    _PageConfig(
      label: 'Page 2',
      type: _PageType.networkImage,
      color: Color(0xFF00BFA5),
      description:
          'Network image via Image.network\n(Issue #9: image rendering)',
    ),
    _PageConfig(
      label: 'Page 3',
      type: _PageType.scrollable,
      color: Color(0xFFFF6D00),
      description:
          'Stack + SingleChildScrollView\n(Issue #4: compositing crash fix)',
    ),
    _PageConfig(
      label: 'Page 4',
      type: _PageType.repaintBoundary,
      color: Color(0xFFAA00FF),
      description: 'RepaintBoundary child\n(Issue #5: native peer crash fix)',
    ),
    _PageConfig(
      label: 'Page 5',
      type: _PageType.interactive,
      color: Color(0xFFD50000),
      description: 'Interactive buttons & gestures\n(tap + long-press test)',
    ),
    _PageConfig(
      label: 'Page 6',
      type: _PageType.gradient,
      color: Color(0xFF00C853),
      description: 'Final page',
    ),
  ];

  TextDirection? _direction;

  @override
  void dispose() {
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: ValueListenableBuilder<int>(
          valueListenable: _currentPage,
          builder: (_, page, __) => Text(
            'Widget Book — Page ${page + 1} / ${_pages.length}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          PopupMenuButton<TextDirection?>(
            initialValue: _direction,
            tooltip: 'Reading Direction',
            icon: Icon(
              _direction == TextDirection.rtl
                  ? Icons.format_textdirection_r_to_l_rounded
                  : _direction == TextDirection.ltr
                  ? Icons.format_textdirection_l_to_r_rounded
                  : Icons.auto_mode_rounded,
              color: const Color(0xFF00E5FF),
            ),
            onSelected: (dir) => setState(() => _direction = dir),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: null,
                child: Text('Auto (System / Directionality)'),
              ),
              PopupMenuItem(
                value: TextDirection.ltr,
                child: Text('LTR (English / Left-to-Right)'),
              ),
              PopupMenuItem(
                value: TextDirection.rtl,
                child: Text('RTL (العربية / Right-to-Left)'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: TurnablePage(
          controller: _controller,
          pageCount: _pages.length,
          pageViewMode: PageViewMode.single,
          paperBoundaryDecoration: PaperBoundaryDecoration.modern,
          textDirection: _direction,
          settings: FlipSettings(
            drawShadow: true,
            hideLeftShadow: true,
            usePortrait: true,
            flippingTime: 700,
            swipeDistance: 60,
            cornerTriggerAreaSize: 0.2,
            enableEasing: true,
            enableInertia: true,
          ),
          onPageChanged: (left, right) {
            _currentPage.value = left;
          },
          builder: (context, pageIndex, constraints) =>
              _PageContent(config: _pages[pageIndex]),
        ),
      ),
      bottomNavigationBar: _BottomNav(controller: _controller, pages: _pages),
    );
  }
}

enum _PageType {
  gradient,
  networkImage,
  scrollable,
  repaintBoundary,
  interactive,
}

class _PageConfig {
  final String label;
  final _PageType type;
  final Color color;
  final String description;

  const _PageConfig({
    required this.label,
    required this.type,
    required this.color,
    required this.description,
  });
}

class _PageContent extends StatelessWidget {
  final _PageConfig config;

  const _PageContent({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: switch (config.type) {
        _PageType.gradient => _GradientPage(config: config),
        _PageType.networkImage => _NetworkImagePage(config: config),
        _PageType.scrollable => _ScrollablePage(config: config),
        _PageType.repaintBoundary => _RepaintBoundaryPage(config: config),
        _PageType.interactive => _InteractivePage(config: config),
      },
    );
  }
}

// ── 1. Simple gradient ────────────────────────────────────────────────────────
class _GradientPage extends StatelessWidget {
  final _PageConfig config;

  const _GradientPage({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [config.color.withValues(alpha: 0.7), config.color],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              config.label,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                config.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Network image (Issue #9 test) ─────────────────────────────────────────
class _NetworkImagePage extends StatelessWidget {
  final _PageConfig config;

  const _NetworkImagePage({required this.config});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://picsum.photos/seed/turnable/600/900',
          fit: BoxFit.cover,
          loadingBuilder: (_, child, event) {
            if (event == null) return child;
            return Container(
              color: config.color.withValues(alpha: 0.15),
              child: Center(
                child: CircularProgressIndicator(color: config.color),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: config.color.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(Icons.broken_image, size: 60, color: Colors.white54),
            ),
          ),
        ),
        // Semi-transparent overlay with label
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  config.description,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3. Scrollable (Issue #4 test) ────────────────────────────────────────────
class _ScrollablePage extends StatelessWidget {
  final _PageConfig config;

  const _ScrollablePage({required this.config});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background color
        Container(color: config.color.withValues(alpha: 0.05)),

        // Scrollable content area (Issue #4 scenario: Stack + SingleChildScrollView)
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: config.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Issue #4 — Stack + ScrollView test',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Long scrollable content
              for (int i = 1; i <= 12; i++)
                _ContentRow(
                  index: i,
                  color: config.color,
                  text:
                      'Scrollable item #$i — This content verifies that '
                      'Stack + SingleChildScrollView renders correctly inside a page-flip '
                      'without layout collapse or compositing crash.',
                ),
            ],
          ),
        ),

        // Floating badge (Stack overlay = also testing Stack compositing)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Compositing OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  final int index;
  final Color color;
  final String text;

  const _ContentRow({
    required this.index,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. RepaintBoundary (Issue #5 stress test) ─────────────────────────────────
class _RepaintBoundaryPage extends StatefulWidget {
  final _PageConfig config;

  const _RepaintBoundaryPage({required this.config});

  @override
  State<_RepaintBoundaryPage> createState() => _RepaintBoundaryPageState();
}

class _RepaintBoundaryPageState extends State<_RepaintBoundaryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.color.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // RepaintBoundary wrapping an animated widget = Issue #5 scenario
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      widget.config.color,
                      widget.config.color.withValues(alpha: 0.1),
                      widget.config.color,
                    ],
                    transform: GradientRotation(_anim.value * 6.28),
                  ),
                ),
                child: const Icon(Icons.sync, color: Colors.white, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.config.label,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: widget.config.color,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.config.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Button that triggers setState (forces repaint while page may be animating)
          ElevatedButton.icon(
            onPressed: () => setState(() => _counter++),
            icon: const Icon(Icons.add),
            label: Text('Repaint #$_counter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.config.color,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RepaintBoundary does NOT crash anymore ✓',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. Interactive buttons ────────────────────────────────────────────────────
class _InteractivePage extends StatefulWidget {
  final _PageConfig config;

  const _InteractivePage({required this.config});

  @override
  State<_InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<_InteractivePage> {
  String _lastEvent = 'None';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.color.withValues(alpha: 0.05),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.touch_app_rounded,
              size: 70,
              color: Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              widget.config.label,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: widget.config.color,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.config.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 32),

            // Tap test
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _lastEvent = 'TAP on button ✓');
                HapticFeedback.lightImpact();
              },
              icon: const Icon(Icons.ads_click),
              label: const Text('Tap Me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.config.color,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 12),

            // Long-press test
            GestureDetector(
              onLongPress: () {
                setState(() => _lastEvent = 'LONG PRESS detected ✓');
                HapticFeedback.mediumImpact();
              },
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: widget.config.color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Long Press Me',
                  style: TextStyle(
                    color: widget.config.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Last event display
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _lastEvent == 'None'
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lastEvent == 'None'
                      ? Colors.grey.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Last event: $_lastEvent',
                style: TextStyle(
                  fontSize: 14,
                  color: _lastEvent == 'None'
                      ? Colors.black38
                      : Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final PageFlipController controller;
  final List<_PageConfig> pages;

  const _BottomNav({required this.controller, required this.pages});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Previous',
            onTap: () async => await controller.previousPage(),
            color: const Color(0xFF00E5FF),
          ),
          _NavBtn(
            icon: Icons.first_page_rounded,
            label: 'First',
            onTap: () async => await controller.animateToFirstPage(),
            color: Colors.white38,
          ),
          _NavBtn(
            icon: Icons.last_page_rounded,
            label: 'Last',
            onTap: () async => await controller.animateToLastPage(),
            color: Colors.white38,
          ),
          _NavBtn(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Next',
            onTap: () async => await controller.nextPage(),
            color: const Color(0xFF00E5FF),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF PICKER SCREEN — choose between asset PDF or network URL
// ─────────────────────────────────────────────────────────────────────────────

class PdfPickerScreen extends StatelessWidget {
  const PdfPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: const Text('PDF Book — Source Selection'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          const Text(
            'Choose a PDF source:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Asset PDF options
          _SectionLabel(label: 'Asset PDFs', icon: Icons.folder_open_rounded),
          const SizedBox(height: 12),
          _PdfSourceCard(
            icon: Icons.description_rounded,
            title: 'CV.pdf (Asset)',
            subtitle: 'Small asset PDF — fast loading',
            accentColor: const Color(0xFFFF6D00),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PdfBookScreen(
                  source: _PdfSource.asset,
                  assetPath: 'assets/CV.pdf',
                  title: 'CV — Asset PDF',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PdfSourceCard(
            icon: Icons.school_rounded,
            title: 'DL Lecture PDF (Asset)',
            subtitle: 'Large asset PDF — tests memory handling',
            accentColor: const Color(0xFFFF6D00),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PdfBookScreen(
                  source: _PdfSource.asset,
                  assetPath: 'assets/DL-CNN-3-Padding-lec11.pdf',
                  title: 'DL Lecture — Large Asset PDF',
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          _SectionLabel(
            label: 'Network PDFs',
            icon: Icons.cloud_download_rounded,
          ),
          const SizedBox(height: 12),
          _PdfSourceCard(
            icon: Icons.public_rounded,
            title: 'Apryse Demo PDF (Network)',
            subtitle: 'Real-world network PDF test',
            accentColor: const Color(0xFF3D5AFE),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PdfBookScreen(
                  source: _PdfSource.network,
                  url:
                      'https://showcase.apryse.com/gallery/WebviewerDemoDoc.pdf',
                  title: 'Apryse Demo — Network PDF',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PdfSourceCard(
            icon: Icons.menu_book_rounded,
            title: 'Flutter Docs PDF (Network)',
            subtitle: 'Tests large network PDF with many pages',
            accentColor: const Color(0xFF3D5AFE),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PdfBookScreen(
                  source: _PdfSource.network,
                  url:
                      'https://www.w3.org/WAI/WCAG21/Techniques/pdf/pdf-techniques.pdf',
                  title: 'WCAG PDF — Large Network PDF',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: Colors.white12)),
      ],
    );
  }
}

class _PdfSourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PdfSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF BOOK SCREEN — actual TurnablePdf viewer
// ─────────────────────────────────────────────────────────────────────────────

enum _PdfSource { asset, network }

class PdfBookScreen extends StatefulWidget {
  final _PdfSource source;
  final String? assetPath;
  final String? url;
  final String title;

  const PdfBookScreen({
    super.key,
    required this.source,
    required this.title,
    this.assetPath,
    this.url,
  });

  @override
  State<PdfBookScreen> createState() => _PdfBookScreenState();
}

class _PdfBookScreenState extends State<PdfBookScreen> {
  final PageFlipController _controller = PageFlipController();
  final ValueNotifier<int> _currentPage = ValueNotifier(0);
  bool _isTwoPageMode = false;
  TextDirection? _direction;

  @override
  void dispose() {
    _currentPage.dispose();
    super.dispose();
  }

  Widget _buildPdfWidget() {
    final settings = FlipSettings(
      drawShadow: true,
      hideLeftShadow: true,
      flippingTime: 700,
      swipeDistance: 60,
      cornerTriggerAreaSize: 0.2,
      usePortrait: !_isTwoPageMode,
    );

    final pageViewMode = _isTwoPageMode
        ? PageViewMode.double
        : PageViewMode.single;

    if (widget.source == _PdfSource.asset) {
      return TurnablePdf.asset(
        widget.assetPath!,
        controller: _controller,
        pageViewMode: pageViewMode,
        paperBoundaryDecoration: PaperBoundaryDecoration.modern,
        settings: settings,
        textDirection: _direction,
        onPageChanged: (left, right) => _currentPage.value = left,
      );
    } else {
      return TurnablePdf.network(
        widget.url!,
        controller: _controller,
        pageViewMode: pageViewMode,
        paperBoundaryDecoration: PaperBoundaryDecoration.modern,
        settings: settings,
        textDirection: _direction,
        onPageChanged: (left, right) => _currentPage.value = left,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B0E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 14)),
            ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (_, page, __) => Text(
                'Page ${page + 1}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          // Direction selector (Auto, LTR, RTL)
          PopupMenuButton<TextDirection?>(
            initialValue: _direction,
            tooltip: 'Reading Direction',
            icon: Icon(
              _direction == TextDirection.rtl
                  ? Icons.format_textdirection_r_to_l_rounded
                  : _direction == TextDirection.ltr
                  ? Icons.format_textdirection_l_to_r_rounded
                  : Icons.auto_mode_rounded,
              color: const Color(0xFFFFAB40),
            ),
            onSelected: (dir) => setState(() => _direction = dir),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: null,
                child: Text('Auto (System / Directionality)'),
              ),
              PopupMenuItem(
                value: TextDirection.ltr,
                child: Text('LTR (English / Left-to-Right)'),
              ),
              PopupMenuItem(
                value: TextDirection.rtl,
                child: Text('RTL (العربية / Right-to-Left)'),
              ),
            ],
          ),
          // Toggle single / two-page mode
          Tooltip(
            message: _isTwoPageMode
                ? 'Switch to single page'
                : 'Switch to two-page spread',
            child: IconButton(
              icon: Icon(
                _isTwoPageMode
                    ? Icons.chrome_reader_mode_outlined
                    : Icons.menu_book_outlined,
                color: const Color(0xFFFFAB40),
              ),
              onPressed: () => setState(() => _isTwoPageMode = !_isTwoPageMode),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF3E1F00), Color(0xFF1A0F0A)],
          ),
        ),
        child: _buildPdfWidget(),
      ),
      bottomNavigationBar: Container(
        height: 72,
        color: const Color(0xFF2D1B0E),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Previous',
              onTap: () => _controller.previousPage(),
              color: const Color(0xFFFFAB40),
            ),
            _NavBtn(
              icon: Icons.first_page_rounded,
              label: 'First',
              onTap: () => _controller.animateToFirstPage(),
              color: Colors.white38,
            ),
            _NavBtn(
              icon: Icons.last_page_rounded,
              label: 'Last',
              onTap: () => _controller.animateToLastPage(),
              color: Colors.white38,
            ),
            _NavBtn(
              icon: Icons.arrow_forward_ios_rounded,
              label: 'Next',
              onTap: () => _controller.nextPage(),
              color: const Color(0xFFFFAB40),
            ),
          ],
        ),
      ),
    );
  }
}
