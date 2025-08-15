import 'package:flutter/material.dart';
import 'source/enums/page_view_mode.dart';
import 'source/flip/flip_settings.dart';
import 'source/model/paper_boundary_decoration.dart';
import 'source/widgets/page_flip_controller.dart';
import 'source/widgets/turnable_page.dart';

void main() {
  runApp(AnimationTestApp());
}

class AnimationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animation Test - اختبار الأنيميشن',
      home: AnimationTestPage(),
    );
  }
}

class AnimationTestPage extends StatefulWidget {
  @override
  _AnimationTestPageState createState() => _AnimationTestPageState();
}

class _AnimationTestPageState extends State<AnimationTestPage> {
  late PageFlipController _controller;
  int _pageCount = 8;

  // استخدام ValueNotifier لتجنب setState أثناء الأنيميشن
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _flipCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _controller = PageFlipController();
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
    _flipCountNotifier.dispose();
    super.dispose();
  }

  Widget _buildTestPage(int index, BoxConstraints constraints) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.primaries[index % Colors.primaries.length].shade300,
            Colors.primaries[index % Colors.primaries.length].shade600,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Test content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, size: 80, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'صفحة ${index + 1}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'اسحب لتقليب الصفحة',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                SizedBox(height: 40),
                // Interactive button for testing
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النقر على زر الصفحة ${index + 1}'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.touch_app),
                  label: Text('اختبار النقر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        Colors.primaries[index % Colors.primaries.length],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Page info overlay
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'اختبار الأنيميشن\nعدد التقليبات: ${_flipCountNotifier.value}',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TurnablePage(
          key: GlobalKey(), // استخدام key ثابت
          controller: _controller,
          pageCount: _pageCount,
          pageViewMode: PageViewMode.single,
          paperBoundaryDecoration: PaperBoundaryDecoration.modern,
          settings: FlipSettings(
            enableSmartGestures: true,
            drawShadow: true,
            flippingTime: 800,
            swipeDistance: 60.0,
            cornerTriggerAreaSize: 0.15,
            usePortrait: false,
          ),
          onPageChanged: (leftPageIndex, rightPageIndex) {
            // تحديث القيم بدون setState لتجنب مقاطعة الأنيميشن
            _currentPageNotifier.value = rightPageIndex;
            _flipCountNotifier.value = _flipCountNotifier.value + 1;
          },
          builder: (context, pageIndex, constraints) {
            return _buildTestPage(pageIndex, constraints);
          },
        ),
      ),
    );
  }
}
