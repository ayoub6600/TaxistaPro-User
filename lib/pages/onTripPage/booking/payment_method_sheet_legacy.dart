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
      // an empty or negative wallet cannot be chosen: start on cash
      if (choosenInPopUp < methods.length && _walletLocked(methods[choosenInPopUp]) && methods.contains('cash')) {
        choosenInPopUp = methods.indexOf('cash');
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
              enabled: !_walletLocked(methods[i]),
              onTap: () {
                if (_walletLocked(methods[i])) return;
                setState(() => choosenInPopUp = i);
              },
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

  double? get _walletBalance => double.tryParse(
      '${etaDetails.isNotEmpty && choosenVehicle != null ? etaDetails[choosenVehicle]['user_wallet_balance'] ?? '' : ''}');

  /// the wallet pays nothing when its balance is zero or below (e.g. -89): it is shown but cannot be chosen
  bool _walletLocked(String type) =>
      (type == 'wallet' || type == 'wallet_and_cash') && ((_walletBalance ?? 1) <= 0 || MarketNotice.foreign);

  String _paymentNote(String type) {
    final rtl = languageDirection == 'rtl';
    switch (type) {
      case 'cash':
        // a negative balance the server would settle on this cash ride (prior_balance_due)
        final due = double.tryParse('${etaDetails.isNotEmpty && choosenVehicle != null ? etaDetails[choosenVehicle]['prior_balance_due'] ?? 0 : 0}') ?? 0;
        if (due > 0) {
          return rtl
              ? 'تدفع للسائق آخر الرحلة، ومعاها ${due.toStringAsFixed(2)} رصيد سابق عليك'
              : 'Pay the driver at the end, plus ${due.toStringAsFixed(2)} of your earlier balance';
        }
        return rtl ? 'تدفع للسائق آخر الرحلة' : 'Pay the driver at the end';
      case 'wallet':
      case 'wallet_and_cash':
        final bal = _walletBalance;
        if (MarketNotice.foreign) {
          return rtl ? 'محفظتك بعملة بلدك، ما تنفعش في هذا البلد · الدفع كاش' : 'Your wallet is in another currency · pay cash here';
        }
        if (bal == null) return rtl ? 'من رصيدك في تاكسيستا' : 'From your Taxista balance';
        if (bal <= 0) {
          return rtl ? 'رصيدك ${bal.toStringAsFixed(2)} · اشحن محفظتك باش تدفع منها' : 'Balance ${bal.toStringAsFixed(2)} · top up to pay with it';
        }
        return rtl ? 'رصيدك ${bal.toStringAsFixed(2)} · لو ما كفاش، الباقي كاش' : 'Balance ${bal.toStringAsFixed(2)} · any rest in cash';
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
