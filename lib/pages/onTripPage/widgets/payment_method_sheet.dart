import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

class PaymentMethodSheet extends StatelessWidget {
  const PaymentMethodSheet({
    super.key,
    required this.methods,
    required this.selectedIndex,
    required this.copy,
    required this.promoController,
    required this.promoStatus,
    required this.onClose,
    required this.onMethodSelected,
    required this.onPromoChanged,
    required this.onPromoRemoved,
    required this.onConfirm,
  });

  final List<String> methods;
  final int selectedIndex;
  final Map<String, dynamic> copy;
  final TextEditingController promoController;
  final int? promoStatus;
  final VoidCallback onClose;
  final ValueChanged<int> onMethodSelected;
  final ValueChanged<String> onPromoChanged;
  final Future<void> Function() onPromoRemoved;
  final Future<void> Function() onConfirm;

  String _text(String key) => copy[key]?.toString() ?? '';

  String _methodDescription(String method) => switch (method) {
        'cash' => _text('text_paycash'),
        'wallet' => _text('text_paywallet'),
        'card' => _text('text_paycard'),
        'upi' => _text('text_payupi'),
        _ => method,
      };

  String _methodAsset(String method) => switch (method) {
        'cash' => 'assets/images/cash.png',
        'wallet' => 'assets/images/wallet.png',
        'card' => 'assets/images/card.png',
        'upi' => 'assets/images/upi.png',
        _ => 'assets/images/cash.png',
      };

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 460.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: page,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _text('text_paymentmethod'),
                            style: GoogleFonts.cairo(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                        ),
                      ],
                    ),
                    Text(
                      _text('text_choose_paynoworlater'),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: hintColor,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ...methods.indexed.map(
                      (entry) => _PaymentMethodTile(
                        method: entry.$2,
                        description: _methodDescription(entry.$2),
                        assetName: _methodAsset(entry.$2),
                        selected: entry.$1 == selectedIndex,
                        onTap: () => onMethodSelected(entry.$1),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: promoController,
                      onChanged: onPromoChanged,
                      enabled: promoStatus == null,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        hintText: _text('text_enterpromo'),
                        filled: true,
                        fillColor: textColor.withValues(alpha: 0.035),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: borderLines),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: borderLines),
                        ),
                        suffixIcon: promoStatus == null
                            ? null
                            : IconButton(
                                onPressed: onPromoRemoved,
                                tooltip: _text('text_remove'),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    if (promoStatus != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        promoStatus == 1
                            ? _text('text_promoaccepted')
                            : _text('text_promorejected'),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: promoStatus == 1
                              ? const Color(0xff16875A)
                              : const Color(0xffDC2626),
                        ),
                      ),
                    ],
                    SizedBox(height: 18.h),
                    Button(
                      onTap: onConfirm,
                      text: _text('text_confirm'),
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.description,
    required this.assetName,
    required this.selected,
    required this.onTap,
  });

  final String method;
  final String description;
  final String assetName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color:
            selected ? buttonColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? buttonColor : borderLines,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: Image.asset(assetName, fit: BoxFit.contain),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.toUpperCase(),
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? buttonColor : hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
