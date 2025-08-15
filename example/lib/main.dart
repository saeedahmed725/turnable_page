import 'dart:developer';

import 'package:example/animation_test.dart';
import 'package:example/source/enums/page_view_mode.dart';
import 'package:example/source/flip/flip_settings.dart';
import 'package:example/source/model/paper_boundary_decoration.dart';
import 'package:example/source/widgets/page_flip_controller.dart';
import 'package:example/source/widgets/turnable_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كتاب ذكي - تطبيق تقليب الصفحات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AnimationTestPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageFlipController _controller;
  final int _totalPages = 6;
  bool _smartGesturesEnabled = true;
  int _buttonPressCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageFlipController();
  }

  Widget _buildPage(int index, BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      decoration: BoxDecoration(color: _getPageColor(index)),
      child: Stack(
        children: [
          // Top section with page number and info
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${index + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _smartGesturesEnabled 
                        ? 'الكشف الذكي: مُفعل\nالأزرار لن تقلب الصفحات'
                        : 'الكشف الذكي: مُعطل\nالأزرار قد تقلب الصفحات',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'عدد النقرات: $_buttonPressCount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Center content with interactive buttons
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPageIcon(index), size: 80, color: Colors.white),
                const SizedBox(height: 30),
                
                // أزرار للاختبار - يجب أن تعمل بدون تقليب للصفحة عند التفعيل الذكي
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _buttonPressCount++;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النقر على الزر! العدد: $_buttonPressCount'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.touch_app),
                  label: Text('زر تفاعلي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _getPageColor(index),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _buttonPressCount++;
                    });
                    _controller.previousPage();
                  },
                  icon: Icon(Icons.navigate_before),
                  label: Text('الصفحة السابقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: _getPageColor(index),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _buttonPressCount++;
                    });
                    _controller.nextPage();
                  },
                  icon: Icon(Icons.navigate_next),
                  label: Text('Next Page'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: _getPageColor(index),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  'Content ${index + 1}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Try tapping the buttons above.\nWith smart gestures enabled, they should work without triggering page flips.\nDrag from page corners to flip pages.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPageColor(int index) {
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.blue[400]!,
      Colors.purple[400]!,
    ];
    return colors[index % colors.length];
  }

  IconData _getPageIcon(int index) {
    final icons = [
      Icons.star,
      Icons.lightbulb,
      Icons.rocket_launch,
      Icons.favorite,
      Icons.celebration,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Gesture Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _smartGesturesEnabled,
            onChanged: (value) {
              setState(() {
                _smartGesturesEnabled = value;
              });
            },
            activeColor: Colors.white,
          ),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Smart Gesture Detection'),
                    content: Text(
                      'When enabled, smart gestures prevent page flips when you tap on interactive widgets like buttons.\n\n'
                      'Try:\n'
                      '• Tap buttons with smart gestures ON/OFF\n'
                      '• Drag from page corners to flip\n'
                      '• Notice the difference in behavior'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: TurnablePage(
          controller: _controller,
          pageCount: _totalPages,
          pageViewMode: PageViewMode.single,
          paperBoundaryDecoration: PaperBoundaryDecoration.modern,
          settings: FlipSettings(
            // تفعيل الكشف الذكي للحركة: سحب = تقليب، نقر = تفاعل مع الودجيت
            enableSmartGestures: _smartGesturesEnabled,
            // حجم المنطقة التي تؤدي لتقليب الصفحة عند النقر (15% من القطر)
            cornerTriggerAreaSize: 0.15,
            drawShadow: true,
            flippingTime: 600,
            // مسافة السحب المطلوبة لتقليب الصفحة
            swipeDistance: 80.0,
          ),
          onPageChanged: (leftPageIndex, rightPageIndex) {
            log('Page changed: $leftPageIndex, $rightPageIndex');
          },
          builder: (context, pageIndex, constraints) {
            return _buildPage(pageIndex, constraints);
          },
        ),
      ),
    );
  }
}
