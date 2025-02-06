import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NewCustomTextFormField extends StatelessWidget {
  const NewCustomTextFormField({
    super.key,
    required this.hint,
    required this.txtController,
    this.obscureText,
    this.readOnly,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.maxLength,
    this.onTap,
    this.style,
    this.onChanged,
    this.counterText,
    this.inputFormatters,
    this.maxLines,
    this.focusNode,
    this.enabled,
  });

  final FocusNode? focusNode;
  final String hint;
  final TextEditingController txtController;
  final bool? obscureText;
  final bool? readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final Function()? onTap;
  final TextStyle? style;
  final Function(String)? onChanged;
  final bool? enabled;
  final String? counterText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      controller: txtController,
      obscureText: obscureText ?? false,
      readOnly: readOnly ?? false,
      onTap: onTap,
      style: style,
      onChanged: onChanged,
      enabled: enabled ?? true,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType ?? TextInputType.text,
      inputFormatters: inputFormatters ?? _getInputFormatters(keyboardType),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        labelStyle: GoogleFonts.cairo(
          color: const Color(0xFF242424),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.0,
        ),
        hintStyle: GoogleFonts.cairo(
          color: const Color(0xff797979),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.0,
        ),
        filled: true,
        fillColor: const Color(0xffF6F6F6),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: counterText,
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildFocusedBorder(context),
      ),
    );
  }

  List<TextInputFormatter>? _getInputFormatters(TextInputType? keyboardType) {
    if (keyboardType == TextInputType.phone ||
        keyboardType == TextInputType.number) {
      return [
        FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ];
    } else if (keyboardType == TextInputType.emailAddress) {
      return [
        FilteringTextInputFormatter.deny(RegExp(r"\s")),
        FilteringTextInputFormatter.allow(
            RegExp(r"[a-zA-Z0-9@.!#$%&'*+/=?^_`{|}~-]+")),
      ];
    }
    return null;
  }

  OutlineInputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    );
  }

  OutlineInputBorder _buildFocusedBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 2.0,
      ),
    );
  }
}
