import 'package:flutter/material.dart';
import 'package:turnable_page/turnable_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TurnablePdf.initPDFLoaders();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turnable PDF Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PDFView(),
    );
  }
}

class PDFView extends StatelessWidget {
  const PDFView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Colors.brown[50]!, Colors.brown[100]!, Colors.brown[200]!],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            TurnablePdf.network(
              'https://showcase.apryse.com/gallery/WebviewerDemoDoc.pdf',
              pageViewMode: PageViewMode.single,
              // aspectRatio: 5/10,
              settings: FlipSettings(),
            ),
            _buildBookmark(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmark(BuildContext context) {
    return Positioned(
      right: MediaQuery.of(context).size.width * 0.17,
      child: Container(
        width: 20,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: CustomPaint(painter: BookmarkPainter()),
      ),
    );
  }
}

class BookmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red[800]!
      ..style = PaintingStyle.fill;

    // Draw bookmark notch at bottom
    final path = Path();
    path.moveTo(0, size.height - 10);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 10);
    path.lineTo(size.width, size.height - 15);
    path.lineTo(0, size.height - 15);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
