import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turnable_page/turnable_page.dart';

void main() => runApp(const PlaygroundApp());

const _accent = Color(0xFFA4471C);

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          brightness: b,
          colorSchemeSeed: _accent,
          useMaterial3: true,
          visualDensity: VisualDensity.compact,
        );
    return MaterialApp(
      title: 'Turnable Page Playground',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const PlaygroundPage(),
    );
  }
}

enum Frame { vintage, modern, parchment, none }

/// Everything the panel can change. Values equal to the package defaults
/// are left out of the generated code.
class Config {
  PageViewMode mode = PageViewMode.auto;
  bool rtl = false;
  bool showCover = false;
  int pageCount = 12;
  Frame frame = Frame.modern;

  bool flipOnTap = true;
  bool directionFromDrag = false;
  bool keepGrabOffset = true;
  bool enableInertia = true;
  bool enableZoom = false;
  bool enableDoubleTapZoom = true;

  int flippingTime = 700;
  bool drawShadow = true;
  bool showCenterShadow = true;
  double maxShadowOpacity = 1.0;
  double bendStrength = 0.6;
  double sagAmplitude = 0.08;
  bool darkPaper = false;

  PaperBoundaryDecoration get decoration => switch (frame) {
        Frame.vintage => PaperBoundaryDecoration.vintage,
        Frame.modern => PaperBoundaryDecoration.modern,
        Frame.parchment => PaperBoundaryDecoration.parchment,
        Frame.none => PaperBoundaryDecoration.none,
      };

  Color get paper => darkPaper ? const Color(0xFF22201D) : Colors.white;

  FlipSettings settings(int startPage) => FlipSettings(
        startPageIndex: startPage,
        showCover: showCover,
        flipOnTap: flipOnTap,
        directionFromDrag: directionFromDrag,
        keepGrabOffset: keepGrabOffset,
        enableInertia: enableInertia,
        flippingTime: flippingTime,
        drawShadow: drawShadow,
        showCenterShadow: showCenterShadow,
        maxShadowOpacity: maxShadowOpacity,
        bendStrength: bendStrength,
        sagAmplitude: sagAmplitude,
        pageBackgroundColor: paper,
      );

  String _num(double v) => v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

  String code() {
    final top = <String>[
      'pageCount: $pageCount,',
      if (mode != PageViewMode.single) 'pageViewMode: PageViewMode.${mode.name},',
      if (rtl) 'textDirection: TextDirection.rtl,',
      if (frame != Frame.vintage)
        'paperBoundaryDecoration: PaperBoundaryDecoration.${frame.name},',
      if (enableZoom) 'enableZoom: true,',
      if (enableZoom && !enableDoubleTapZoom) 'enableDoubleTapZoom: false,',
    ];
    final s = <String>[
      if (showCover) 'showCover: true,',
      if (!flipOnTap) 'flipOnTap: false,',
      if (directionFromDrag) 'directionFromDrag: true,',
      if (!keepGrabOffset) 'keepGrabOffset: false,',
      if (!enableInertia) 'enableInertia: false,',
      if (flippingTime != 700) 'flippingTime: $flippingTime,',
      if (!drawShadow) 'drawShadow: false,',
      if (!showCenterShadow) 'showCenterShadow: false,',
      if (maxShadowOpacity != 1.0) 'maxShadowOpacity: ${_num(maxShadowOpacity)},',
      if (bendStrength != 0.6) 'bendStrength: ${_num(bendStrength)},',
      if (sagAmplitude != 0.08) 'sagAmplitude: ${_num(sagAmplitude)},',
      if (darkPaper) 'pageBackgroundColor: const Color(0xFF22201D),',
    ];
    final b = StringBuffer('TurnablePage(\n');
    for (final l in top) {
      b.writeln('  $l');
    }
    if (s.isNotEmpty) {
      b.writeln('  settings: FlipSettings(');
      for (final l in s) {
        b.writeln('    $l');
      }
      b.writeln('  ),');
    }
    b.writeln('  builder: (context, index, constraints) => MyPage(index),');
    b.write(')');
    return b.toString();
  }
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final c = Config();
  final controller = PageFlipController();
  int page = 0;
  int version = 0;
  bool showCode = false;

  /// Settings changes rebuild the book from scratch on the current page,
  /// so every option applies at once.
  void update(VoidCallback f) => setState(() {
        f();
        version++;
      });

  void snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final book = _BookArea(
      key: ValueKey(version),
      config: c,
      controller: controller,
      startPage: page.clamp(0, c.pageCount - 1),
      onPageChanged: (i) => setState(() => page = i),
      onPageButton: (i) => snack('Button on page ${i + 1} tapped'),
    );
    final panel = _Panel(
      config: c,
      update: update,
      showCode: showCode,
      onToggleCode: () => setState(() => showCode = !showCode),
      onCopy: () {
        Clipboard.setData(ClipboardData(text: c.code()));
        snack('Code copied');
      },
    );
    final nav = _NavBar(
      controller: controller,
      page: page,
      count: c.pageCount,
      onChanged: () => setState(() {}),
    );

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(children: [
                SizedBox(width: 330, child: panel),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(children: [
                    Expanded(child: book),
                    nav,
                  ]),
                ),
              ])
            : Column(children: [
                Expanded(flex: 11, child: book),
                nav,
                const Divider(height: 1),
                Expanded(flex: 9, child: panel),
              ]),
      ),
    );
  }
}

class _BookArea extends StatelessWidget {
  const _BookArea({
    super.key,
    required this.config,
    required this.controller,
    required this.startPage,
    required this.onPageChanged,
    required this.onPageButton,
  });

  final Config config;
  final PageFlipController controller;
  final int startPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageButton;

  @override
  Widget build(BuildContext context) {
    final c = config;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      child: TurnablePage(
        controller: controller,
        pageCount: c.pageCount,
        pageViewMode: c.mode,
        textDirection: c.rtl ? TextDirection.rtl : TextDirection.ltr,
        paperBoundaryDecoration: c.decoration,
        pagesBoundaryIsEnabled: c.frame != Frame.none,
        enableZoom: c.enableZoom,
        enableDoubleTapZoom: c.enableDoubleTapZoom,
        settings: c.settings(startPage),
        onPageChanged: (left, right) => onPageChanged(left),
        builder: (context, index, constraints) => _DemoPage(
          index: index,
          count: c.pageCount,
          dark: c.darkPaper,
          rtl: c.rtl,
          onButton: () => onPageButton(index),
        ),
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({
    required this.index,
    required this.count,
    required this.dark,
    required this.rtl,
    required this.onButton,
  });

  final int index;
  final int count;
  final bool dark;
  final bool rtl;
  final VoidCallback onButton;

  static const _tints = [
    Color(0xFFA4471C),
    Color(0xFF2E6F8E),
    Color(0xFF5B7F3A),
    Color(0xFF8A4F9E),
    Color(0xFFB0812A),
    Color(0xFF3F5BA9),
  ];

  @override
  Widget build(BuildContext context) {
    final paper = dark ? const Color(0xFF22201D) : Colors.white;
    final ink = dark ? const Color(0xFFE9E2D6) : const Color(0xFF2A2621);
    final line = dark ? const Color(0xFF3A3631) : const Color(0xFFECE7DF);
    final tint = _tints[index % _tints.length];
    final isCover = index == 0 || index == count - 1;

    if (isCover) {
      return Container(
        color: tint,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, color: Colors.white, size: 44),
            const SizedBox(height: 14),
            Text(
              index == 0 ? (rtl ? 'الغلاف' : 'Turnable Page') : (rtl ? 'النهاية' : 'The End'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              index == 0 ? 'Drag a corner to begin' : 'Thanks for reading',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Container(
      color: paper,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: LayoutBuilder(builder: (context, box) {
        final lines = ((box.maxHeight - 190) / 16).floor().clamp(2, 14);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rtl ? 'الفصل $index' : 'Chapter $index',
              style: TextStyle(color: tint, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              rtl ? 'صفحة تفاعلية' : 'An interactive page',
              style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < lines; i++)
              Container(
                height: 7,
                margin: const EdgeInsets.only(bottom: 9),
                width: box.maxWidth * (i % 4 == 3 ? 0.6 : 1),
                decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4)),
              ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: onButton,
              style: FilledButton.styleFrom(backgroundColor: tint.withValues(alpha: .15), foregroundColor: tint),
              child: Text(rtl ? 'اضغط هنا' : 'Tap me'),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Text('${index + 1}', style: TextStyle(color: ink.withValues(alpha: .5), fontSize: 12)),
            ),
          ],
        );
      }),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.controller,
    required this.page,
    required this.count,
    required this.onChanged,
  });

  final PageFlipController controller;
  final int page;
  final int count;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'First page',
            icon: const Icon(Icons.first_page),
            onPressed: () => controller.animateToFirstPage(),
          ),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => controller.previousPage(),
          ),
          SizedBox(
            width: 70,
            child: Text('${page + 1} / $count', textAlign: TextAlign.center),
          ),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => controller.nextPage(),
          ),
          IconButton(
            tooltip: 'Last page',
            icon: const Icon(Icons.last_page),
            onPressed: () => controller.animateToLastPage(),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.config,
    required this.update,
    required this.showCode,
    required this.onToggleCode,
    required this.onCopy,
  });

  final Config config;
  final void Function(VoidCallback) update;
  final bool showCode;
  final VoidCallback onToggleCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text(text.toUpperCase(),
              style: t.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1, color: t.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    Widget toggle(String label, bool value, ValueChanged<bool> set, {String? sub, bool enabled = true}) =>
        SwitchListTile(
          dense: true,
          title: Text(label),
          subtitle: sub == null ? null : Text(sub),
          value: value,
          onChanged: enabled ? (v) => update(() => set(v)) : null,
        );

    Widget slider(String label, double value, double min, double max, ValueChanged<double> set,
            {int? divisions, String Function(double)? fmt}) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label, style: t.textTheme.bodyMedium)),
              Text(fmt?.call(value) ?? value.toStringAsFixed(2), style: t.textTheme.bodySmall),
              const SizedBox(width: 8),
            ]),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) => update(() => set(v)),
            ),
          ]),
        );

    Widget segmented<T>(List<(T, String)> options, T value, ValueChanged<T> set) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [for (final (v, l) in options) ButtonSegment(value: v, label: Text(l))],
              selected: {value},
              onSelectionChanged: (s) => update(() => set(s.first)),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(children: [
            Expanded(child: Text('Playground', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
            TextButton.icon(
              onPressed: onToggleCode,
              icon: Icon(showCode ? Icons.tune : Icons.code, size: 18),
              label: Text(showCode ? 'Options' : 'Code'),
            ),
          ]),
        ),
        if (showCode) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1C19),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              c.code(),
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: Color(0xFFEDE6DA)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(onPressed: onCopy, icon: const Icon(Icons.copy, size: 16), label: const Text('Copy code')),
          ),
        ] else ...[
          header('Layout'),
          segmented<PageViewMode>(
            const [(PageViewMode.single, 'Single'), (PageViewMode.double, 'Double'), (PageViewMode.auto, 'Auto')],
            c.mode,
            (v) => c.mode = v,
          ),
          segmented<Frame>(
            const [(Frame.modern, 'Modern'), (Frame.vintage, 'Vintage'), (Frame.parchment, 'Parch.'), (Frame.none, 'None')],
            c.frame,
            (v) => c.frame = v,
          ),
          toggle('Right-to-left', c.rtl, (v) => c.rtl = v, sub: 'Arabic, Hebrew, Persian'),
          toggle('Show cover', c.showCover, (v) => c.showCover = v, sub: 'First and last pages alone in a spread'),
          header('Gestures'),
          toggle('Flip on tap', c.flipOnTap, (v) => c.flipOnTap = v,
              sub: 'Off: taps reach page buttons, even in corners'),
          toggle('Direction from drag', c.directionFromDrag, (v) => c.directionFromDrag = v,
              sub: 'Single page: turn by swipe direction'),
          toggle('Keep grab offset', c.keepGrabOffset, (v) => c.keepGrabOffset = v),
          toggle('Inertia', c.enableInertia, (v) => c.enableInertia = v, sub: 'A fast fling finishes the turn'),
          header('Zoom'),
          toggle('Pinch-to-zoom', c.enableZoom, (v) => c.enableZoom = v),
          toggle('Double-tap zoom', c.enableDoubleTapZoom, (v) => c.enableDoubleTapZoom = v,
              enabled: c.enableZoom),
          header('Animation'),
          slider('Flipping time', c.flippingTime.toDouble(), 200, 1500, (v) => c.flippingTime = v.round(),
              divisions: 26, fmt: (v) => '${v.round()} ms'),
          slider('Bend strength', c.bendStrength, 0, 1, (v) => c.bendStrength = v, divisions: 20),
          slider('Sag amplitude', c.sagAmplitude, 0, 0.2, (v) => c.sagAmplitude = v, divisions: 20),
          header('Shadows and paper'),
          toggle('Shadows', c.drawShadow, (v) => c.drawShadow = v),
          toggle('Spine shadow', c.showCenterShadow, (v) => c.showCenterShadow = v, enabled: c.drawShadow),
          slider('Shadow opacity', c.maxShadowOpacity, 0, 1, (v) => c.maxShadowOpacity = v, divisions: 20),
          toggle('Dark paper', c.darkPaper, (v) => c.darkPaper = v, sub: 'Sets pageBackgroundColor'),
          header('Book'),
          slider('Pages', c.pageCount.toDouble(), 4, 40, (v) => c.pageCount = v.round(),
              divisions: 36, fmt: (v) => '${v.round()}'),
        ],
      ],
    );
  }
}
