import 'package:flutter/material.dart';
import 'package:taxista/constants/text_style.dart';

class ChooseGender extends StatefulWidget {
  final ValueChanged<String> onGenderSelected;

  const ChooseGender({super.key, required this.onGenderSelected});

  @override
  _ChooseGenderState createState() => _ChooseGenderState();
}

class _ChooseGenderState extends State<ChooseGender> {
  String selectedGender = 'male'; // Default value

  void _selectGender(String value) {
    setState(() {
      selectedGender = value;
    });
    widget.onGenderSelected(value); // Pass gender to parent
  }

  Widget _buildGenderOption(String label, String value) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectGender(value), // Update state on tap
        child: Row(
          children: [
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 1.2, color: Colors.black),
              ),
              alignment: Alignment.center,
              child: (selectedGender == value)
                  ? Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.black),
                    )
                  : Container(),
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: AppStyle.style14W500Black,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildGenderOption('Male', 'male'),
        _buildGenderOption('Female', 'female'),
      ],
    );
  }
}
