import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../passport/widgets/passport_view.dart' show openExternal;

/// SplitSure customer support on WhatsApp.
const kSupportWhatsAppUrl = 'https://wa.me/237692407316';

/// Floating "Customer support" chat button, pinned to the right edge around the
/// middle of the screen. It opens with its label, folds into a round button after a
/// few seconds and keeps a soft pulse so it stays noticeable. Tap → WhatsApp chat.
class SupportChatButton extends StatefulWidget {
  const SupportChatButton({super.key});

  @override
  State<SupportChatButton> createState() => _SupportChatButtonState();
}

class _SupportChatButtonState extends State<SupportChatButton> with TickerProviderStateMixin {
  static const _green = Color(0xFF25D366);
  static const _darkGreen = Color(0xFF128C7E);

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _expanded = true;
  Timer? _fold;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _enter.forward();
    });
    _fold = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _fold?.cancel();
    _pulse.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _open() => openExternal(kSupportWhatsAppUrl);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = MediaQuery.of(context).size.height;
    final slide = CurvedAnimation(parent: _enter, curve: Curves.elasticOut);
    return Positioned(
      right: 0,
      top: h * 0.62 - 28,
      child: AnimatedBuilder(
        animation: slide,
        builder: (_, child) => Transform.translate(offset: Offset(90 * (1 - slide.value), 0), child: child),
        child: Semantics(
          button: true,
          label: l10n.supportChatTooltip,
          child: Tooltip(
            message: l10n.supportChatTooltip,
            child: GestureDetector(
              onTap: _open,
              onLongPress: () => setState(() => _expanded = !_expanded),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                // Label that folds away.
                AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  child: _expanded
                      ? Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.supportChatTitle,
                                    style: const TextStyle(
                                        fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF142B4A))),
                                Text(l10n.supportChatSubtitle,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              ]),
                        )
                      : const SizedBox.shrink(),
                ),
                // Round button with a pulse ring, tucked against the edge.
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(34)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(-2, 4)),
                    ],
                  ),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) {
                          final t = _pulse.value;
                          return Container(
                            width: 48 + 18 * t,
                            height: 48 + 18 * t,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _green.withValues(alpha: 0.35 * (1 - t)),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) => Transform.rotate(
                          // A small "wiggle" once per pulse.
                          angle: _pulse.value < 0.18 ? math.sin(_pulse.value / 0.18 * math.pi * 3) * 0.12 : 0,
                          child: child,
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_green, _darkGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 27),
                        ),
                      ),
                      // WhatsApp mark on the corner.
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _green, width: 1.5),
                          ),
                          child: const Center(child: FaIcon(FontAwesomeIcons.whatsapp, color: _darkGreen, size: 12)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
