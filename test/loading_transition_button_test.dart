import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loading_transition_button/loading_transition_button.dart';

void main() {
  late LoadingButtonController controller;

  setUp(() {
    controller = LoadingButtonController();
  });
  testWidgets('The widget has a title', (WidgetTester tester) async {
    final title = 'Hit me';
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingButton(
          color: Colors.blue,
          onSubmit: () => print('onSubmit'),
          controller: controller,
          errorColor: Colors.red,
          transitionDuration: Duration(seconds: 1),
          child: Text(title),
        ),
      ),
    );

    expect(find.text(title), findsOneWidget);
  });

  testWidgets('The widget has a progress indicator when the state is loading',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingButton(
          color: Colors.blue,
          onSubmit: () => print('onSubmit'),
          controller: controller,
          errorColor: Colors.red,
          transitionDuration: Duration(seconds: 1),
          child: Text('Hit me'),
        ),
      ),
    );

    controller.startLoadingAnimation();

    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('When the buttons it tapped, the onSubmitCallback is called',
      (WidgetTester tester) async {
    bool callbackCalled = false;
    final onSubmitCallback = () => callbackCalled = true;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadingButton(
          color: Colors.blue,
          onSubmit: onSubmitCallback,
          controller: controller,
          errorColor: Colors.red,
          transitionDuration: Duration(seconds: 1),
          child: Text('Hit me'),
        ),
      ),
    );

    await tester.tap(find.byType(LoadingButton));

    await tester.pump();

    expect(callbackCalled, true);
  });
}
