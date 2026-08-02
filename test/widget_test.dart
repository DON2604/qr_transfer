import 'package:flutter_test/flutter_test.dart';
import 'package:qr_transfer/main.dart';

void main() {
  testWidgets('App renders main navigation tabs smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QrTransferApp());
    expect(find.text('AirTransfer QR'), findsOneWidget);
    expect(find.text('Send (QR)'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
