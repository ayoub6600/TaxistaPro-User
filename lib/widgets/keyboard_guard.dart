import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS can leave the keyboard up after its text field is gone (a sheet closed, a page replaced),
/// and then nothing on the screen can close it. Any touch closes a keyboard that no field owns.
class KeyboardGuard extends StatelessWidget {
  const KeyboardGuard({super.key, required this.child});

  final Widget child;

  static bool get _fieldHasFocus => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (MediaQuery.viewInsetsOf(context).bottom > 0 && !_fieldHasFocus) {
            SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          }
        },
        child: child,
      );
}
