part of '../bookingwidgets.dart';

class VehicleInfoBottomSheet extends StatelessWidget {
  final int i;
  final double width;
  final bool isOneway;
  final dynamic type;
  const VehicleInfoBottomSheet({
    super.key,
    required this.i,
    required this.width,
    required this.isOneway,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final details = type != 1 ? etaDetails[i] : rentalOption[choosenVehicle];
    final iconUrl = details['icon']?.toString().trim() ?? '';
    return Container(
      width: width * 1,
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(width * 0.08),
              topRight: Radius.circular(width * 0.08))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: iconUrl.isEmpty
                ? const Icon(Icons.local_taxi_rounded,
                    size: 60, color: Colors.blue)
                : Image.network(
                    iconUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_taxi_rounded,
                        size: 60,
                        color: Colors.blue),
                  ),
          ),

          SizedBox(
            height: width * 0.02,
          ),
          //name
          MyText(
            text: (type != 1)
                ? (etaDetails[i]['name']?.toString() ?? '')
                : '${rentalOption[choosenVehicle]['name']} (${etaDetails[rentalChoosenOption]['package_name']})',
            // : '${etaDetails[i]['typesWithPrice']['data'][0]['name']} (${etaDetails[i]['package_name']})',
            size: 16.sp,
            color: Colors.blue,
            // fontweight: FontWeight.bold,
          ),
          SizedBox(
            height: width * 0.03,
          ),
          //discrption

          MyText(
            text: ((type != 1))
                ? (etaDetails[i]['short_description']?.toString() ?? '')
                : (rentalOption[choosenVehicle]['short_description']
                        ?.toString() ??
                    ''),
            size: 12.sp,
            color: Colors.grey,
          ),
          SizedBox(
            height: width * 0.05,
          ),

          (((etaDetails[i]['enable_bidding'] == false && isOneway) ||
                  (type == 1 || type == 2)))
              ? Container(
                  width: width * 0.9,
                  padding: EdgeInsets.all(width * 0.02),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: hintColor.withValues(alpha: 0.01)),
                  child: GestureDetector(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (type != 2)
                              MyText(
                                  text: choosenLanguage == 'ar'
                                      ? 'الأجرة'
                                      : 'Fare',
                                  size: width * fourteen),
                            if (type != 2)
                              (etaDetails[i]['has_discount'] != true)
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        (type != 1)
                                            ? Text(
                                                (etaDetails[i]['currency'] +
                                                    etaDetails[i]['total']
                                                        .toString()),
                                                style: GoogleFonts.notoSans(
                                                    fontSize: width * fourteen,
                                                    fontWeight: FontWeight.w700,
                                                    color: (choosenVehicle != i)
                                                        ? (isDarkTheme == true)
                                                            ? Colors.white
                                                            : textColor
                                                        : textColor),
                                              )
                                            : Text(
                                                etaDetails[i]['currency'] +
                                                    rentalOption[choosenVehicle]
                                                            ['fare_amount']
                                                        .toString(),
                                                style: GoogleFonts.notoSans(
                                                    fontSize: width * fourteen,
                                                    fontWeight: FontWeight.w700,
                                                    color: (choosenVehicle != i)
                                                        ? (isDarkTheme == true)
                                                            ? Colors.white
                                                            : textColor
                                                        : textColor),
                                              ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          etaDetails[i]['currency'] + ' ',
                                          style: GoogleFonts.notoSans(
                                              fontSize: width * fourteen,
                                              color: (choosenVehicle != i)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              (type != 1)
                                                  ? etaDetails[i]['total']
                                                      .toString()
                                                  : rentalOption[choosenVehicle]
                                                          ['fare_amount']
                                                      .toString(),
                                              style: GoogleFonts.notoSans(
                                                  fontSize: width * fourteen,
                                                  color: (choosenVehicle != i)
                                                      ? (isDarkTheme == true)
                                                          ? Colors.white
                                                          : textColor
                                                      : Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration
                                                      .lineThrough),
                                            ),
                                            Text(
                                              (type != 1)
                                                  ? etaDetails[i]
                                                          ['discounted_totel']
                                                      .toString()
                                                  : rentalOption[choosenVehicle]
                                                          ['discounted_totel']
                                                      .toString(),
                                              style: GoogleFonts.notoSans(
                                                  fontSize: width * fourteen,
                                                  color: (choosenVehicle != i)
                                                      ? (isDarkTheme == true)
                                                          ? Colors.white
                                                          : textColor
                                                      : Colors.black,
                                                  fontWeight: FontWeight.w700),
                                            )
                                          ],
                                        ),
                                      ],
                                    )
                          ],
                        ),
                        SizedBox(
                          height: width * 0.02,
                        ),
                        FareBreakupDetails(
                            width: width,
                            heading: choosenLanguage == 'ar'
                                ? 'سعر الدقيقة'
                                : 'Time Price',
                            value: (type != 1)
                                ? '${etaDetails[i]['currency']} ${etaDetails[i]['price_per_time']} / min'
                                : '${etaDetails[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['time_price_per_min'].toString()} / min'),
                        SizedBox(
                          height: width * 0.02,
                        ),
                        FareBreakupDetails(
                            width: width,
                            heading: choosenLanguage == 'ar'
                                ? 'سعر المسافة'
                                : 'Distance Price',
                            value: (type != 1)
                                ? '${etaDetails[i]['currency']} ${etaDetails[i]['price_per_distance']} / ${etaDetails[i]['unit_in_words']}'
                                : '${etaDetails[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['distance_price_per_km'].toString()} / ${rentalOption[choosenVehicle]['unit_in_words']}'),
                        SizedBox(
                          height: width * 0.02,
                        ),
                        FareBreakupDetails(
                            width: width,
                            heading: choosenLanguage == 'ar'
                                ? 'طرق الدفع'
                                : 'Payment Types',
                            value: (type != 1)
                                ? _paymentMethodsLabel(
                                    etaDetails[i]['payment_type']?.toString() ??
                                        '')
                                : _paymentMethodsLabel(
                                    rentalOption[choosenVehicle]['payment_type']
                                            ?.toString() ??
                                        '')),
                      ],
                    ),
                  ),
                )
              : Container(),
          SizedBox(
            height: width * 0.05,
          ),
          Row(
            children: [
              Expanded(
                child: MyText(
                    text: ((type != 1))
                        ? (etaDetails[i]['description']?.toString() ?? '')
                        : (rentalOption[choosenVehicle]['description']
                                ?.toString() ??
                            ''),
                    color: textColor.withValues(alpha: 0.6),
                    size: width * fourteen),
              )
            ],
          ),
          const SizedBox(height: 12),
          // Wrap(
          //   spacing: 6,
          //   runSpacing: 6,
          //   children: etaDetails[i]['supported_vehicles']
          //       .split(',') // تحويل النص إلى قائمة
          //       .take(5) // أخذ أول 5 عناصر فقط
          //       .map<Widget>((vehicle) {
          //     // تحديد نوع العنصر المُرجع
          //     return Chip(
          //       label: Text(vehicle.trim(),
          //           style: const TextStyle(
          //               fontSize: 12)), // إزالة المسافات الزائدة
          //     );
          //   }).toList(), // تحويل Iterable إلى List
          // ),
        ],
      ),
    );
  }

  String _paymentMethodsLabel(String raw) {
    if (choosenLanguage != 'ar') return raw.replaceAll('_', ' ');
    final methods = raw.split(',').toSet();
    return [
      if (methods.contains('cash') || methods.contains('wallet_and_cash'))
        'نقدًا',
      if (methods.contains('wallet') || methods.contains('wallet_and_cash'))
        'المحفظة',
      if (methods.contains('card')) 'البطاقة',
    ].join('، ');
  }
}
