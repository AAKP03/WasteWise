import 'package:flutter_test/flutter_test.dart';
import 'package:wastewise/main.dart';

void main() {
  testWidgets('App shows the three navigation tabs',
          (WidgetTester tester) async {
        await tester.pumpWidget(const WasteWiseApp());

        expect(find.text('Categories'), findsWidgets);
        expect(find.text('Map'), findsWidgets);
        expect(find.text('Eco Points'), findsWidgets);
      });
}