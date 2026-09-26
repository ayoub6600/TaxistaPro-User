import 'package:flutter/material.dart';

import 'moamalat_env.dart';
import 'smart_fill_controller.dart';

const Color _successGreen = Color(0xff0E8A4B);

/// The friendly helper shown above the payment page when the bank's card form
/// is on screen: our own character offers "Smart Fill", says up front what the
/// tap does (fills the saved card AND accepts the payment terms), then confirms
/// and gets out of the way. It sits ABOVE the payment page (never over it), so
/// it cannot cover a Moamalat control, and it shrinks to one slim row when the
/// keyboard is open.
class SmartFillAssistant extends StatelessWidget {
  const SmartFillAssistant({super.key, required this.env, required this.controller});

  final MoamalatEnv env;
  final SmartFillController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final phase = controller.phase;
        final visible = phase == SmartFillPhase.ready ||
            phase == SmartFillPhase.filling ||
            phase == SmartFillPhase.success ||
            phase == SmartFillPhase.failed;
        final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        Widget child;
        if (!visible) {
          child = const SizedBox.shrink(key: ValueKey('smart-fill-hidden'));
        } else if (phase == SmartFillPhase.success && controller.collapsed) {
          child = _chip();
        } else if (keyboardOpen) {
          child = _compact(phase);
        } else {
          child = _card(phase);
        }
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: child),
        );
      },
    );
  }

  // ---- copy ---------------------------------------------------------------------------------------
  String get _consent => env.t('بالضغط على تعبئة ذكية، سيتم تعبئة بيانات بطاقتك والموافقة على شروط الدفع.',
      'Tap Smart Fill and we will fill in your card details and accept the payment terms.');

  String _title(SmartFillPhase phase) {
    switch (phase) {
      case SmartFillPhase.success:
        return env.t('تمام 👌 بيانات البطاقة جاهزة، كمّل عملية الدفع.', 'All set 👌 Your card details are ready - continue the payment.');
      case SmartFillPhase.failed:
        return controller.lastResult?.formNotRecognised == true
            ? env.t('تعذر تعبئة البطاقة تلقائياً', 'We could not fill in the card automatically')
            : env.t('تعذر إكمال التعبئة، حاول مرة أخرى', 'We could not finish filling in - please try again');
      default:
        return env.t('نقدر نعبّيلك بيانات البطاقة تلقائياً 👌', 'We can fill in your card details for you 👌');
    }
  }

  String _buttonLabel(SmartFillPhase phase) {
    switch (phase) {
      case SmartFillPhase.success:
        return env.t('✓ تمت التعبئة بنجاح', '✓ Filled successfully');
      case SmartFillPhase.failed:
        return env.t('إعادة المحاولة', 'Try again');
      default:
        return env.t('تعبئة ذكية', 'Smart Fill');
    }
  }

  // ---- pieces -------------------------------------------------------------------------------------
  Widget _mascot(double size) {
    final asset = controller.support.assistantAsset;
    final fullBody = asset.endsWith('rider_mascot.png'); // a full-length character: show head and shoulders
    final image = Image.asset(
      asset,
      width: size,
      height: fullBody ? size * 1.6 : size,
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(child: OverflowBox(alignment: Alignment.topCenter, maxHeight: fullBody ? size * 1.6 : size, child: image)),
    );
  }

  Widget _button(SmartFillPhase phase, {bool compact = false}) {
    final busy = phase == SmartFillPhase.filling;
    final done = phase == SmartFillPhase.success;
    final label = Text(_buttonLabel(phase), maxLines: 1, overflow: TextOverflow.ellipsis, style: env.style(size: compact ? 12.5 : 14.5, weight: FontWeight.w800, color: Colors.white));
    final button = FilledButton(
      key: const Key('smart-fill-button'),
      style: FilledButton.styleFrom(
        backgroundColor: done ? _successGreen : env.accent,
        disabledBackgroundColor: done ? _successGreen : env.accent.withOpacity(0.55),
        minimumSize: Size(compact ? 96 : 0, compact ? 38 : 46),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      ),
      onPressed: (busy || done) ? null : controller.fill,
      child: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          : label,
    );
    return compact ? button : SizedBox(width: double.infinity, child: button);
  }

  BoxDecoration get _box => BoxDecoration(
        color: env.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: env.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      );

  Widget _card(SmartFillPhase phase) {
    final success = phase == SmartFillPhase.success;
    return Container(
      key: const Key('smart-fill-card'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: _box,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _mascot(50),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_title(phase), key: const Key('smart-fill-title'), style: env.style(size: 13.5, weight: FontWeight.w800)),
              if (!success) ...[
                const SizedBox(height: 3),
                Text(_consent, key: const Key('smart-fill-consent'), style: env.style(size: 11.5, weight: FontWeight.w500, color: env.muted)),
              ],
            ]),
          ),
          InkWell(
            key: const Key('smart-fill-minimize'),
            onTap: controller.collapse,
            borderRadius: BorderRadius.circular(16),
            child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: env.muted)),
          ),
        ]),
        const SizedBox(height: 10),
        _button(phase),
      ]),
    );
  }

  /// One slim row while the keyboard is open - the consent sentence stays visible.
  Widget _compact(SmartFillPhase phase) {
    final success = phase == SmartFillPhase.success;
    return Container(
      key: const Key('smart-fill-compact'),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: _box,
      child: Row(children: [
        _mascot(34),
        const SizedBox(width: 8),
        Expanded(
          child: Text(success ? _title(phase) : (phase == SmartFillPhase.failed ? _title(phase) : _consent),
              key: const Key('smart-fill-compact-text'), maxLines: 3, overflow: TextOverflow.ellipsis, style: env.style(size: 10.5, weight: FontWeight.w600, color: env.muted)),
        ),
        const SizedBox(width: 8),
        _button(phase, compact: true),
      ]),
    );
  }

  /// After success the panel gets out of the way: a small green chip, tap to open it again.
  Widget _chip() {
    return Align(
      key: const Key('smart-fill-chip'),
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: InkWell(
          onTap: controller.expand,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 12, 4),
            decoration: BoxDecoration(color: _successGreen.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: _successGreen.withOpacity(0.35))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _mascot(24),
              const SizedBox(width: 6),
              Text(env.t('✓ تمت التعبئة', '✓ Filled'), style: env.style(size: 12, weight: FontWeight.w800, color: _successGreen)),
            ]),
          ),
        ),
      ),
    );
  }
}
