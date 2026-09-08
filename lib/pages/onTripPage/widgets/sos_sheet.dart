import 'package:flutter/material.dart';

import '../../../styles/styles.dart';

class SosSheet extends StatelessWidget {
  const SosSheet({
    super.key,
    required this.copy,
    required this.contacts,
    required this.notificationSent,
    required this.onClose,
    required this.onNotifyAdmin,
    required this.onCall,
  });

  final Map copy;
  final List contacts;
  final bool notificationSent;
  final VoidCallback onClose;
  final Future<void> Function() onNotifyAdmin;
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: media.width * 0.84,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filled(
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      backgroundColor: page,
                      foregroundColor: textColor,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(maxHeight: media.height * 0.55),
                    decoration: BoxDecoration(
                      color: page,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ListTile(
                          onTap: onNotifyAdmin,
                          leading: Icon(
                            notificationSent
                                ? Icons.check_circle_rounded
                                : Icons.notification_add_rounded,
                            color: notificationSent
                                ? const Color(0xff319900)
                                : buttonColor,
                          ),
                          title: Text(
                            '${copy['text_notifyadmin']}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: notificationSent
                              ? Text(
                                  '${copy['text_notifysuccess']}',
                                  style: const TextStyle(
                                    color: Color(0xff319900),
                                  ),
                                )
                              : null,
                        ),
                        if (contacts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '${copy['text_noDataFound']}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...contacts.map(
                            (contact) => ListTile(
                              onTap: () => onCall(
                                '${contact['number']}'.replaceAll(' ', ''),
                              ),
                              leading: Icon(
                                Icons.call_rounded,
                                color: buttonColor,
                              ),
                              title: Text(
                                '${contact['name']}',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('${contact['number']}'),
                            ),
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
