part of '../bookingwidgets.dart';

class FareBreakupDetails extends StatelessWidget {
  final double width;
  final String heading;
  final String value;
  const FareBreakupDetails(
      {super.key,
      required this.width,
      required this.heading,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(text: heading, size: width * fourteen),
        MyText(
            text: value.toString(),
            fontweight: FontWeight.bold,
            size: width * fourteen)
      ],
    );
  }
}

bool choosePets = false;
bool chooseLuggages = false;
