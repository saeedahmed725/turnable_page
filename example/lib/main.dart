import 'dart:developer';

import 'package:example/source/enums/page_view_mode.dart';
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
      title: 'Page Flip Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
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
  final int _totalPages = 5;

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
          // Page number in top corner
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  // show snack bar or perform action
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Page ${index + 1} clicked!')),
                  );
                },
                child: Text(
                  'Page ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Content in center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPageIcon(index), size: 80, color: Colors.white),
                const SizedBox(height: 20),
                TextButton(onPressed: (){
                  // show snack bar or perform action
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Button on Page ${index + 1} clicked!')),
                  );
                }, child: Text(
                  'Content ${index + 1}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
                ),
                const SizedBox(height: 10),
                Text(
                  'This is the content for page ${index + 1}.\nIt should be visible when you flip to this page.',
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
      Colors.purple[400]!,
    ];
    return colors[index % colors.length];
  }

  IconData _getPageIcon(int index) {
    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.lightbulb,
      Icons.rocket_launch,
      Icons.celebration,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TurnablePage(
          controller: _controller,
          pageCount: _totalPages,
          pageViewMode: PageViewMode.single,
          paperBoundaryDecoration: PaperBoundaryDecoration.vintage,
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
