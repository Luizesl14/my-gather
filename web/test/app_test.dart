import "package:flutter_test/flutter_test.dart";

import "package:love_robot_web/app.dart";
import "package:love_robot_web/features/workspace/presentation/game/office_canvas.dart";

void main() {
  testWidgets("navega pelos placeholders iniciais", (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text("Login"), findsOneWidget);

    await tester.tap(find.text("Entrar"));
    await tester.pumpAndSettle();
    expect(find.text("Organizações"), findsOneWidget);

    await tester.tap(find.text("Continuar"));
    await tester.pumpAndSettle();
    expect(find.text("Escritórios"), findsOneWidget);

    await tester.tap(find.text("Abrir"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Escritório"), findsOneWidget);
    expect(find.text("office-default"), findsWidgets);
    expect(find.byType(OfficeCanvas), findsOneWidget);
  });
}
