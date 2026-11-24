import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/payment_service.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../models/subscription.dart';
import '../widgets/payment_sheet.dart';
import '../services/receipt_service.dart';

/// Opens the Pro upgrade payment and celebrates when the server confirms it.
Future<bool> startProUpgrade(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showPaymentSheet(
    context,
    type: PaymentType.proUpgrade,
    amountFcfa: ref.read(proPriceProvider),
    title: l10n.upgradeToPro,
  );
  if (ok) {
    ref.invalidate(entitlementProvider);
    if (context.mounted) await showProWelcome(context);
  }
  return ok;
}

Future<void> showProWelcome(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF5B301), size: 56),
      title: Text(l10n.proWelcomeTitle, textAlign: TextAlign.center),
      content: Text(l10n.proWelcomeBody, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.continueLabel),
        ),
      ],
    ),
  );
}

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ent = ref.watch(entitlementProvider).whenOrNull(data: (e) => e) ?? Entitlement.free;
    final history = ref.watch(paymentHistoryProvider).whenOrNull(data: (h) => h) ?? const [];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(entitlementProvider);
          ref.invalidate(paymentHistoryProvider);
        },
        child: CustomScrollView(slivers: [
          AppSliverHeader(
            title: l10n.subscriptionStatus,
            subtitle: planLabel(l10n, ent.planId),
            leading: const HeaderIcon(Icons.workspace_premium_rounded),
            showBack: true,
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    FadeSlideIn(child: CurrentPlanCard(entitlement: ent)),
                    const SizedBox(height: 24),
                    Text(l10n.chooseAPlan,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: stagger(1),
                      child: PlanOptionsRow(
                        isPro: ent.isPro,
                        onFree: null,
                        onPro: ent.isPro ? null : () => startProUpgrade(context, ref),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.paymentHistory,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                    const SizedBox(height: 12),
                    if (history.isEmpty)
                      Text(l10n.noPayments,
                          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText))
                    else
                      for (var i = 0; i < history.length; i++)
                        FadeSlideIn(delay: stagger(i), child: _PaymentRow(tx: history[i])),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Summary of the user's plan (used on Subscription and Profile).
class CurrentPlanCard extends StatelessWidget {
  final Entitlement entitlement;
  const CurrentPlanCard({super.key, required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = entitlement.isPro;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: pro ? kHeroGradient : kNavyGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))
        ],
      ),
      child: Column(children: [
        Icon(pro ? Icons.workspace_premium_rounded : Icons.person_outline_rounded,
            color: pro ? const Color(0xFFF5B301) : Colors.white, size: 40),
        const SizedBox(height: 8),
        Text(pro ? l10n.youAreOnPro : l10n.youAreOnFree,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          pro && entitlement.proActivatedAt != null
              ? l10n.proActiveSince(formatDate(entitlement.proActivatedAt!))
              : l10n.proUnlocksBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.35),
        ),
      ]),
    );
  }
}

/// Free vs Pro cards. Used by the plan picker after sign-up and the Subscription screen.
class PlanOptionsRow extends ConsumerWidget {
  final bool isPro;
  final VoidCallback? onFree;
  final VoidCallback? onPro;
  final bool busy;
  const PlanOptionsRow({super.key, required this.isPro, this.onFree, this.onPro, this.busy = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fcfa = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final plans = ref.watch(plansProvider).whenOrNull(data: (p) => p) ?? kDefaultPlans;
    final free = plans.where((p) => p.id == 'free').firstOrNull;
    final proPrice = ref.watch(proPriceProvider);
    final maxProjects = free?.features['max_projects']?.limit ?? 3;
    String price(int v) => l10n.amountFcfa(fcfa.format(v));

    // pinButton: only when the cards sit side by side with a bounded height (see below).
    Widget freeCard({bool pinButton = false}) => _PlanCard(
          pinButton: pinButton,
          name: l10n.freePlan,
          price: price(0),
          caption: l10n.freeForever,
          features: [
            l10n.freeFeaturePassport,
            l10n.freeFeatureProtectDrafts,
            l10n.freeFeatureAgreementFee(price(50)),
            l10n.freeFeatureOnePost,
            l10n.freeFeatureProjects(maxProjects),
          ],
          isCurrent: !isPro,
          buttonLabel: onFree != null ? l10n.continueWithFree : null,
          onPressed: busy ? null : onFree,
        );
    Widget proCard({bool pinButton = false}) => _PlanCard(
          pinButton: pinButton,
          name: l10n.proPlan,
          price: price(proPrice),
          caption: l10n.oneTimePayment,
          features: [
            l10n.proFeatureUnlimitedPosts,
            l10n.proFeatureUnlimitedAgreements,
            l10n.proFeatureReach,
            l10n.proFeatureUnlimitedProjects,
          ],
          highlighted: true,
          isCurrent: isPro,
          buttonLabel: isPro ? null : l10n.upgradeForAmount(price(proPrice)),
          onPressed: busy ? null : onPro,
        );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 620) {
        // Side by side: equal heights, buttons pinned to the bottom of each card.
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: freeCard(pinButton: true)),
            const SizedBox(width: 14),
            Expanded(child: proCard(pinButton: true)),
          ]),
        );
      }
      return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [proCard(), const SizedBox(height: 14), freeCard()]);
    });
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String caption;
  final List<String> features;
  final bool highlighted;
  final bool isCurrent;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  /// Pushes the button to the bottom. Only valid when the parent gives the card a
  /// bounded height (side-by-side cards); stacked in a scroll view it must be false.
  final bool pinButton;

  const _PlanCard({
    this.pinButton = false,
    required this.name,
    required this.price,
    required this.caption,
    required this.features,
    this.highlighted = false,
    this.isCurrent = false,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlighted ? AppColors.teal : AppColors.cardBorder, width: highlighted ? 2 : 1),
        boxShadow: highlighted
            ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))]
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Wraps the badge under the name when the card is narrow (e.g. long French labels).
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (highlighted) const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF5B301), size: 22),
              if (highlighted) const SizedBox(width: 6),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            ]),
            if (highlighted && !isCurrent) _Chip(l10n.recommended, AppColors.teal),
            if (isCurrent) _Chip(l10n.current, AppColors.success),
          ],
        ),
        const SizedBox(height: 10),
        Text(price,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: highlighted ? AppColors.teal : AppColors.deepNavy)),
        Text(caption, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 12.5)),
        const SizedBox(height: 14),
        for (final f in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.check_circle_rounded, size: 18, color: highlighted ? AppColors.teal : AppColors.mutedText),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: const TextStyle(fontSize: 13.5, color: AppColors.deepNavy))),
            ]),
          ),
        if (buttonLabel != null) ...[
          if (pinButton) const Spacer(),
          const SizedBox(height: 8),
          highlighted
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onPressed,
                  child: Text(buttonLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onPressed,
                  child: Text(buttonLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
        ],
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _PaymentRow extends ConsumerWidget {
  final PaymentTransaction tx;
  const _PaymentRow({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fcfa = NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    final color = switch (tx.status) {
      'success' => AppColors.success,
      'pending' => Colors.orange,
      _ => AppColors.error,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              tx.provider == 'MTN' ? 'assets/images/subscrib/mtn.jpg' : 'assets/images/subscrib/orange.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.type == 'PRO_UPGRADE' ? l10n.paymentTypePro : l10n.paymentTypeAgreement,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              Text('${formatDate(tx.createdAt)} · ${tx.provider} · ${tx.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l10n.amountFcfa(fcfa.format(tx.amountFcfa)),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            Text(paymentStatusLabel(l10n, tx.status),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ]),
        ]),
        if (tx.status == 'success') ...[
          const Divider(height: 20, color: AppColors.cardBorder),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => downloadReceipt(context, ref, tx),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(l10n.downloadReceipt),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal, visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ]),
    );
  }
}
