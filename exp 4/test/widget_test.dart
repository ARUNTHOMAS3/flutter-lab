// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exp4/main.dart';

class TestImage extends StatelessWidget {
  final double width;
  final double height;
  const TestImage({Key? key, this.width = 60, this.height = 60}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey,
      child: const Center(child: Icon(Icons.image)),
    );
  }
}

void main() {
  testWidgets('App builds and displays title', (WidgetTester tester) async {
    // Override Image.network to avoid network calls in tests
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed.
    expect(find.text('🌍 Famous Places Map'), findsOneWidget);
  });
}
