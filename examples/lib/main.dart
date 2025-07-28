import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:turnable_page/turnable_page.dart';

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
      home: const HomePage(),
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
  int _currentPage = 0;
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
      decoration: BoxDecoration(
        color: _getPageColor(index),
        border: Border.all(color: Colors.black, width: 2),
      ),
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
          // Content in center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPageIcon(index), size: 80, color: Colors.white),
                const SizedBox(height: 20),
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
      appBar: AppBar(title: const Text('Turnable Page Examples')),
      body: Column(
        children: [
          // Control panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller.previousPage();
                  },
                  child: const Text('Previous'),
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.nextPage();
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
          // Page flip widget
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Center(
                child: TurnablePage.twoPages(
                  controller: _controller,
                  pageBuilder: _buildPage,
                  pageCount: _totalPages,
                  onPageChanged: (leftPageIndex, rightPageIndex) {
                    log('Page changed: $leftPageIndex, $rightPageIndex');
                    // Update current page index based on left page index
                    setState(() {
                      _currentPage = leftPageIndex;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
