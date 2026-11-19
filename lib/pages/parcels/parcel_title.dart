import 'dart:async';

import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';

/// «نوصلولك طرود ← أمانات ← توصيل»: the admin's words, one every two and a half seconds
/// (owner 2026-11-19). One word, or a phone that asks for less motion, stays still.
class ParcelTitle extends StatefulWidget {
  const ParcelTitle({super.key, required this.words});

  final List<String> words;

  @override
  State<ParcelTitle> createState() => _ParcelTitleState();
}

class _ParcelTitleState extends State<ParcelTitle> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.words.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (mounted && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) setState(() => _i = (_i + 1) % widget.words.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words.isEmpty ? '' : widget.words[_i % widget.words.length];
    return Semantics(
      label: '${tr('نوصلولك', 'We deliver')} ${widget.words.join('، ')}',
      excludeSemantics: true,
      child: Row(children: [
        Text(tr('نوصلولك ', 'We deliver '), style: IcStyle.t(22, w: FontWeight.w900)),
        Flexible(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, .6), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: a, child: child),
              ),
              layoutBuilder: (cur, prev) => Stack(alignment: AlignmentDirectional.centerStart, children: [...prev, if (cur != null) cur]),
              child: Text(word, key: ValueKey(word), maxLines: 1, style: IcStyle.t(22, w: FontWeight.w900, c: IcStyle.blue)),
            ),
          ),
        ),
        const Text(' 📦', style: TextStyle(fontSize: 20)),
      ]),
    );
  }
}
