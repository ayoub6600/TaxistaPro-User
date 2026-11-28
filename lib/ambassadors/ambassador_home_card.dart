import 'dart:async';

import 'package:flutter/material.dart';

import 'ambassadors_api.dart';
import 'ambassadors_kit.dart';
import 'ambassadors_pages.dart';

/// The home card of the campaign (board Campaign): «جيب صحابك واكسب», his code and what he earned
/// (the server's words), «شوف» opens «سفراء تاكسيستا», × hides it on this phone for 7 days.
class AmbassadorHomeCard extends StatelessWidget {
  const AmbassadorHomeCard({super.key, required this.card, this.onOpen, this.onClose});

  final AmbassadorHomeCardData card;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  void _open(BuildContext context) {
    if (onOpen != null) return onOpen!();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AmbassadorsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('amb-home-card'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF).withValues(alpha: .97),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D9FF)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AmbLook.blue, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(card.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmbLook.t(14.5, w: FontWeight.w800, h: 1.4)),
                  if (card.sub.isNotEmpty)
                    Text(card.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmbLook.t(12.5, color: const Color(0xFF334155))),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: AmbLook.blue, borderRadius: BorderRadius.circular(999)),
                child: Text('شوف', style: AmbLook.t(13.5, w: FontWeight.w800, color: Colors.white)),
              ),
              Semantics(
                button: true,
                label: 'اخفي',
                excludeSemantics: true,
                child: GestureDetector(
                  key: const ValueKey('amb-home-close'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose ?? () => unawaited(AmbassadorsApi.hideHomeCard()),
                  child: const SizedBox(
                    width: 34,
                    height: 44,
                    child: Center(child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
