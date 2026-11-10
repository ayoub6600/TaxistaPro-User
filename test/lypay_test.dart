import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/payments/lypay/lypay_api.dart';
import 'package:taxista/payments/lypay/lypay_pages.dart';
import 'package:taxista/payments/moamalat/add_money_sheet.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';

/// «تحويل LYPay»: the account with copy buttons and the four steps, the screenshot and the amount,
/// then the line sent → checking → topped up (or the admin's reason), first in the Add Money sheet.
class _Methods implements MoamalatApi {
  @override
  Future<List<PaymentMethodOption>> methods() async => const [
        PaymentMethodOption(key: 'lypay_transfer', labelAr: 'تحويل LYPay', labelEn: 'LYPay transfer'),
        PaymentMethodOption(key: 'qareeb_card', labelAr: 'كرت شحن تاكسيستا', labelEn: 'Taxista recharge card'),
      ];
  @override
  Future<MoamalatOptions> options() async => MoamalatOptions.unavailable;
  @override
  Future<MoamalatTopUp> initiate(double amount) => throw UnimplementedError();
  @override
  Future<MoamalatStatus> status(String topUpId) => throw UnimplementedError();
}

class _Lypay implements LypayApi {
  LypayRequest? open;
  String next = 'checking';
  final sent = <double>[];

  LypayRequest _req(String status) => LypayRequest(
        reference: 'TOP-ABC123',
        status: status,
        amount: 50,
        amountCredited: status == 'approved' ? 45 : null,
        rejectReason: status == 'rejected' ? 'المبلغ ما وصلش للحساب' : null,
        sentAt: DateTime(2026, 11, 10, 16, 12),
        reviewedAt: status == 'approved' || status == 'rejected' ? DateTime(2026, 11, 10, 16, 19) : null,
      );

  @override
  Future<LypayInfo> info() async => LypayInfo(
        available: true,
        account: const LypayAccount(bankName: 'مصرف الجمهورية', accountName: 'شركة تاكسيستا', iban: 'LY830020000012345678901', accountNumber: '0020000012345'),
        minAmount: 10,
        openRequest: open,
      );

  @override
  Future<LypayRequest> submit(double amount, File receipt) async {
    sent.add(amount);
    return _req('sent');
  }

  @override
  Future<LypayRequest> status(String reference) async => _req(next);
}

void main() {
  late _Lypay lypay;
  late int walletReloads;
  late File png;
  String? copied;

  setUpAll(() {
    png = File('${Directory.systemTemp.createTempSync('ly').path}/r.png')
      ..writeAsBytesSync(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='));
  });

  setUp(() {
    lypay = _Lypay();
    walletReloads = 0;
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
  });

  MoamalatEnv env() => MoamalatEnv(
        api: _Methods(),
        vault: CardVault(store: MemorySecretStore(), ownerId: '1'),
        clipboard: SecureClipboard(writer: (_) async {}),
        isRtl: true,
        lypay: lypay,
        onWalletChanged: () => walletReloads++,
      );

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: TextButton(onPressed: () => showAddMoneySheet(context, env: env(), onQareeb: () {}), child: const Text('go'))),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('LYPay is first in Add Money and opens the account with copy buttons and four steps', (tester) async {
    await openSheet(tester);
    expect(find.text('تحويل LYPay'), findsOneWidget);
    expect(find.text('حوّل من تطبيق مصرفك، ونشحنها لك خلال دقائق'), findsOneWidget);
    expect(tester.getTopLeft(find.text('تحويل LYPay')).dy, lessThan(tester.getTopLeft(find.text('أدخل رمز بطاقة الشحن')).dy));

    await tester.tap(find.text('تحويل LYPay'));
    await tester.pumpAndSettle();
    expect(find.text('حوّل لحساب تاكسيستا'), findsOneWidget);
    expect(find.text('LY83 0020 0000 1234 5678 901'), findsOneWidget, reason: 'grouped like the bank app');
    expect(find.textContaining('خذ سكرين شوت'), findsOneWidget);

    await tester.tap(find.byKey(const Key('copy-الآيبان IBAN · من أي مصرف')));
    await tester.pump();
    expect(copied, 'LY830020000012345678901', reason: 'copied without the spaces');
    await tester.tap(find.byKey(const Key('copy-رقم الحساب · لو نفس المصرف')));
    await tester.pump();
    expect(copied, '0020000012345');
  });

  testWidgets('screenshot + amount, then the line moves by itself to «تم شحن محفظتك»', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => openLypay(context, env: env(), api: lypay, picker: () async => png), child: const Text('go')),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lypay-transferred')));
    await tester.pumpAndSettle();
    expect(find.text('الخطوة 2 من 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lypay-send')));
    await tester.pump();
    expect(find.text('أرفق صورة التحويل'), findsOneWidget);
    expect(lypay.sent, isEmpty);

    await tester.tap(find.byKey(const Key('lypay-pick')));
    await tester.pump();
    expect(find.text('✓ الصورة جاهزة'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lypay-amount')), '٥');
    await tester.tap(find.byKey(const Key('lypay-send')));
    await tester.pump();
    expect(lypay.sent, isEmpty, reason: 'below the minimum');

    await tester.enterText(find.byKey(const Key('lypay-amount')), '٥٠');
    await tester.tap(find.byKey(const Key('lypay-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(lypay.sent, [50.0], reason: 'Arabic digits work');
    expect(find.text('تم إرسال الطلب'), findsOneWidget);
    expect(find.text('جاري التأكد من الحوالة'), findsOneWidget);
    expect(find.text('تم شحن محفظتك'), findsOneWidget, reason: 'still waiting in the line');

    lypay.next = 'approved';
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('تم التأكد'), findsOneWidget);
    expect(find.text('+45 د.ل'), findsWidgets, reason: 'the amount the admin credited');
    expect(find.text('رجوع للمحفظة'), findsOneWidget);
    expect(walletReloads, 1);
  });

  testWidgets('a request still open goes straight to its line; a rejection shows the reason', (tester) async {
    lypay.open = lypay._req('checking');
    lypay.next = 'rejected';
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(body: TextButton(onPressed: () => openLypay(context, env: env(), api: lypay), child: const Text('go'))),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('جاري التأكد من الحوالة'), findsOneWidget);
    expect(find.text('حوّل لحساب تاكسيستا'), findsNothing);

    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('ما لقيناش الحوالة'), findsOneWidget);
    expect(find.textContaining('المبلغ ما وصلش للحساب'), findsOneWidget);
    expect(find.text('ابعث الصورة من جديد'), findsOneWidget);
    expect(walletReloads, 0);
  });
}
