import 'package:flutter/material.dart';

import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

class RiderContactSheet extends StatelessWidget {
  const RiderContactSheet({
    super.key,
    required this.copy,
    required this.nameController,
    required this.numberController,
    required this.instructionsController,
    required this.onClose,
    required this.onPickContact,
    required this.onConfirm,
  });

  final Map copy;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final TextEditingController instructionsController;
  final VoidCallback onClose;
  final Future<void> Function() onPickContact;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: media.height * 0.72),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                color: page,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${copy['text_give_user_data']}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: media.width * sixteen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '${copy['text_pick_contact'] ?? ''}',
                          onPressed: onPickContact,
                          icon: const Icon(Icons.contact_page_rounded),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ContactField(
                      controller: nameController,
                      hint: '${copy['text_name']}',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    _ContactField(
                      controller: numberController,
                      hint: '${copy['text_givenumber']}',
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                    ),
                    const SizedBox(height: 12),
                    _ContactField(
                      controller: instructionsController,
                      hint: '${copy['text_instructions']}',
                      keyboardType: TextInputType.multiline,
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Button(onTap: onConfirm, text: copy['text_confirm']),
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

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: topBar,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hintColor.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hintColor.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: buttonColor, width: 1.5),
        ),
      ),
    );
  }
}
