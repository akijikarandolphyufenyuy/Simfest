import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/passport.dart';
import '../widgets/passport_view.dart';
import 'passport_wizard_screen.dart';
import 'public_passport_screen.dart';

Future<void> openPassportWizard(BuildContext context, {MusicPassport? existing, int step = 0}) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => PassportWizardScreen(existing: existing, initialStep: step)));

void copyPassportLink(BuildContext context, String slug) {
  Clipboard.setData(ClipboardData(text: passportLink(slug)));
  showSuccess(context, AppLocalizations.of(context)!.linkCopied);
}

/// "Music Passport" section: the owner's passport, or the creation intro the first time.
class PassportScreen extends ConsumerWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const PassportScreen({super.key, this.showBack = true, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myPassportProvider);
    final passport = async.whenOrNull(data: (p) => p);
    final portfolio = ref.watch(myPortfolioProvider).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {
          ref.invalidate(myPassportProvider);
          ref.invalidate(myPortfolioProvider);
        },
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(
            title: l10n.musicPassport,
            subtitle: passport == null
                ? l10n.passportTagline
                : (passport.isPublished ? l10n.passportLive : l10n.passportDraft),
            leading: const HeaderIcon(Icons.badge_rounded),
            showBack: showBack || onBack != null,
            onBackOverride: onBack,
            actions: [
              if (passport != null)
                IconButton(
                  tooltip: l10n.editPassport,
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () => openPassportWizard(context, existing: passport),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  child: async.isLoading && passport == null
                      ? const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
                      : passport == null
                          ? _Intro(onCreate: () => openPassportWizard(context))
                          : PassportView(
                              passport: passport,
                              portfolio: portfolio,
                              actions: [
                                if (passport.isPublished) ...[
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                                    onPressed: () => copyPassportLink(context, passport.slug),
                                    icon: const Icon(Icons.share_rounded, size: 18),
                                    label: Text(l10n.sharePassport),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => PublicPassportScreen(slug: passport.slug))),
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    label: Text(l10n.previewPublic),
                                  ),
                                ] else
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                                    onPressed: () => openPassportWizard(context, existing: passport, step: 3),
                                    icon: const Icon(Icons.public_rounded, size: 18),
                                    label: Text(l10n.publishPassport),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => openPassportWizard(context, existing: passport),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(l10n.editPassport),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final VoidCallback onCreate;
  const _Intro({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: kHeroGradient),
            child: const Icon(Icons.badge_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 16),
          Text(l10n.musicPassport,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          Text(l10n.createPassportIntro,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, height: 1.45)),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.createPassport, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

/// Ensures the user has a published passport before posting/applying; offers to create it.
Future<bool> requirePublishedPassport(BuildContext context, WidgetRef ref) async {
  final p = await ref.read(myPassportProvider.future);
  if (p != null && p.isPublished) return true;
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.badge_rounded, color: AppColors.teal, size: 42),
      title: Text(l10n.passportRequiredTitle, textAlign: TextAlign.center),
      content: Text(l10n.passportRequiredBody, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.notNow)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(p == null ? l10n.createPassport : l10n.publishPassport),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) await openPassportWizard(context, existing: p, step: p == null ? 0 : 3);
  return false;
}
