import 'package:flutter/material.dart';

import '../../../styles/styles.dart';

class LocationPermissionSheet extends StatelessWidget {
  const LocationPermissionSheet({
    super.key,
    required this.message,
    required this.openSettingsText,
    required this.doneText,
    required this.onClose,
    required this.onOpenSettings,
    required this.onDone,
  });

  final String message;
  final String openSettingsText;
  final String doneText;
  final VoidCallback onClose;
  final Future<void> Function() onOpenSettings;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: media.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      backgroundColor: page,
                      foregroundColor: buttonColor,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(media.width * 0.05),
                    decoration: BoxDecoration(
                      color: page,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: media.width * sixteen,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: onOpenSettings,
                              child: Text(openSettingsText),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: onDone,
                              style: FilledButton.styleFrom(
                                backgroundColor: buttonColor,
                              ),
                              child: Text(doneText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
