part of '../bookingwidgets.dart';

int choosenInPopUp = 0;

class ChoosePaymentMethodContainer extends StatefulWidget {
  final dynamic type;
  final dynamic onTap;
  const ChoosePaymentMethodContainer(
      {super.key, this.type, required this.onTap});

  @override
  State<ChoosePaymentMethodContainer> createState() =>
      _ChoosePaymentMethodContainerState();
}

class _ChoosePaymentMethodContainerState
    extends State<ChoosePaymentMethodContainer> {
  @override
  void initState() {
    // choosenInPopUp = 0;
    choosenInPopUp = payingVia;
    if (widget.type != 1 && choosenVehicle != null) {
      final methods =
          etaDetails[choosenVehicle]['payment_type'].toString().split(',');
      if (choosenInPopUp < methods.length &&
          methods[choosenInPopUp] == 'wallet_and_cash' &&
          methods.contains('wallet')) {
        choosenInPopUp = methods.indexOf('wallet');
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = languageDirection == 'rtl';
    final rental = !(choosenVehicle != null && widget.type != 1);
    final methods = (rental ? rentalOption[choosenVehicle]['payment_type'] : etaDetails[choosenVehicle]['payment_type'])
        .toString()
        .split(',');
    // design v2: the same choices (index into payment_type, as before), as option cards
    return V2SheetFrame(
      title: languages[choosenLanguage]['text_choose_payment'] ?? (rtl ? 'اختر طريقة الدفع' : 'Choose payment'),
      subtitle: rtl ? 'تقدر تغيرها قبل ما تطلب' : 'You can change it before you request',
      icon: Icons.account_balance_wallet_outlined,
      primaryLabel: languages[choosenLanguage]['text_confirm'] ?? (rtl ? 'تأكيد' : 'Confirm'),
      onPrimary: widget.onTap,
      child: Column(children: [
        for (var i = 0; i < methods.length; i++)
          if (!(methods[i] == 'wallet_and_cash' && methods.contains('wallet')))
            V2OptionRow(
              title: _getTranslatedPaymentType(methods[i] == 'wallet_and_cash' ? 'wallet' : methods[i]),
              note: _paymentNote(methods[i]),
              icon: _paymentIcon(methods[i]),
              selected: choosenInPopUp == i,
              onTap: () => setState(() => choosenInPopUp = i),
            ),
      ]),
    );
  }

  IconData _paymentIcon(String type) => switch (type) {
        'cash' => Icons.payments_outlined,
        'wallet' || 'wallet_and_cash' => Icons.account_balance_wallet_outlined,
        'card' => Icons.credit_card_rounded,
        _ => Icons.qr_code_rounded,
      };

  String _paymentNote(String type) {
    final rtl = languageDirection == 'rtl';
    switch (type) {
      case 'cash':
        return rtl ? 'تدفع للسائق آخر الرحلة' : 'Pay the driver at the end';
      case 'wallet':
      case 'wallet_and_cash':
        final bal = double.tryParse('${etaDetails.isNotEmpty && choosenVehicle != null ? etaDetails[choosenVehicle]['user_wallet_balance'] ?? '' : ''}');
        return bal == null ? (rtl ? 'من رصيدك في تاكسيستا' : 'From your Taxista balance') : (rtl ? 'رصيدك ${bal.toStringAsFixed(2)}' : 'Balance ${bal.toStringAsFixed(2)}');
      case 'card':
        return rtl ? 'بطاقتك البنكية' : 'Your bank card';
      default:
        return '';
    }
  }

  String _getTranslatedPaymentType(String paymentType) {
    switch (paymentType) {
      case 'cash':
        return languages[choosenLanguage]['text_cash'];
      case 'wallet':
        return languages[choosenLanguage]['text_wallet'];
      case 'wallet_and_cash':
        return languages[choosenLanguage]['text_wallet_plus_cash'];
      case 'card':
        return languages[choosenLanguage]['text_card'];
      case 'upi':
        return languages[choosenLanguage]['text_upi'];
      default:
        return paymentType; // Fallback to original text if no translation found
    }
  }
}

bool confirmRideLater = false;
