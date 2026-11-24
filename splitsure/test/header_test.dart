import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/shared/widgets/app_header.dart';

void main() {
  Widget page(Widget header) => MaterialApp(
        home: Scaffold(
          body: CustomScrollView(slivers: [
            header,
            SliverList(delegate: SliverChildBuilderDelegate((_, i) => SizedBox(height: 80, child: Text('row $i')), childCount: 40)),
          ]),
        ),
      );

  Finder headerBox() => find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(SizedBox)).first;

  testWidgets('sliver header keeps one fixed height and position while scrolling', (tester) async {
    await tester.pumpWidget(page(const AppSliverHeader(title: 'Protect', subtitle: 'Your agreements')));
    final before = tester.getRect(headerBox());
    expect(before.height, kHeaderHeight);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final after = tester.getRect(headerBox());
    expect(after, before, reason: 'header must not shrink or move');
    expect(find.text('Protect'), findsOneWidget);
    expect(find.text('Your agreements'), findsOneWidget);
  });

  testWidgets('form app bar has the same height as screen headers', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: GradientAppBar(title: 'New agreement'))));
    expect(tester.getSize(find.byType(GradientAppBar)).height, kHeaderHeight + kHeaderGap);
  });
}
