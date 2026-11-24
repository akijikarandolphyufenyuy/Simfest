import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../hub/models/opportunity.dart';
import '../../hub/screens/opportunity_detail_screen.dart';
import '../models/passport.dart';
import '../../../core/services/session_prefs.dart';
import '../widgets/passport_join_gate.dart';
import '../widgets/passport_view.dart';
import 'passport_screen.dart';

/// Public Music Passport page: /passport/<slug>. Works signed out.
class PublicPassportScreen extends ConsumerStatefulWidget {
  final String slug;
  const PublicPassportScreen({super.key, required this.slug});

  @override
  ConsumerState<PublicPassportScreen> createState() => _PublicPassportScreenState();
}

class _PublicPassportScreenState extends ConsumerState<PublicPassportScreen> {
  final _portfolioKey = GlobalKey();

  bool get _signedIn => Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    // Visitors without an account: remember this passport so sign-up / sign-in
    // brings them straight back here (see the router redirect).
    if (!_signedIn) rememberReturnPath('/passport/${widget.slug}');
  }

  void _contact(MusicPassport p) {
    final l10n = AppLocalizations.of(context)!;
    final hasAny = (p.contactEmail?.isNotEmpty ?? false) || (p.contactPhone?.isNotEmpty ?? false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.contact,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (!hasAny)
              Text(l10n.noContactPublic,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
            if (p.contactEmail?.isNotEmpty ?? false)
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.teal),
                title: Text(p.contactEmail!),
                onTap: () => openExternal('mailto:${p.contactEmail}'),
              ),
            if (p.contactPhone?.isNotEmpty ?? false) ...[
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppColors.teal),
                title: Text(p.contactPhone!),
                onTap: () => openExternal('tel:${p.contactPhone}'),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                title: Text(l10n.contactWhatsapp),
                onTap: () => openExternal('https://wa.me/${p.contactPhone!.replaceAll(RegExp(r'\D'), '')}'),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _collaborate(MusicPassport p) {
    final l10n = AppLocalizations.of(context)!;
    if (!_signedIn) {
      context.go('/register');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final list =
            ref.watch(ownerOpenOpportunitiesProvider(p.userId)).whenOrNull(data: (l) => l) ?? const <Opportunity>[];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l10n.openOpportunitiesBy(p.stageName),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (list.isEmpty) ...[
                Text(l10n.noOpenOpportunitiesBy(p.stageName),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _contact(p);
                  },
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(l10n.contact),
                ),
              ],
              for (final o in list)
                ListTile(
                  leading: const Icon(Icons.work_outline_rounded, color: AppColors.teal),
                  title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(opportunityCategoryLabel(l10n, o.category)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunityId: o.id)));
                  },
                ),
            ]),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(publicPassportBySlugProvider(widget.slug));
    final p = async.whenOrNull(data: (p) => p);
    final portfolio = p == null
        ? const <PortfolioItem>[]
        : (ref.watch(publicPortfolioProvider(p.userId)).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[]);
    final canPop = Navigator.of(context).canPop();

    // Shared link opened without an account → ask to join (or sign in) first.
    if (!_signedIn) {
      return async.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.teal)))
          : PassportJoinGate(passport: p);
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: p?.stageName ?? l10n.musicPassport,
          subtitle: l10n.musicPassport,
          leading: const HeaderIcon(Icons.badge_rounded),
          showBack: canPop,
          actions: [
            if (!canPop)
              TextButton(
                onPressed: () => context.go(_signedIn ? '/home' : '/register'),
                child: Text(_signedIn ? 'SplitSure' : l10n.joinSplitSure,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                child: async.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
                    : p == null
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(children: [
                              const Icon(Icons.badge_outlined, size: 56, color: AppColors.mutedText),
                              const SizedBox(height: 12),
                              Text(l10n.passportNotFound, textAlign: TextAlign.center),
                            ]),
                          )
                        : PassportView(
                            passport: p,
                            portfolio: p.portfolioPublic ? portfolio : const [],
                            portfolioKey: _portfolioKey,
                            actions: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                                onPressed: () => _collaborate(p),
                                icon: const Icon(Icons.handshake_rounded, size: 18),
                                label: Text(_signedIn ? l10n.collaborate : l10n.signInToCollaborate),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _contact(p),
                                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                                label: Text(l10n.contact),
                              ),
                              if (portfolio.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () => Scrollable.ensureVisible(_portfolioKey.currentContext!,
                                      duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic),
                                  icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                                  label: Text(l10n.viewPortfolio),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => copyPassportLink(context, p.slug),
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: Text(l10n.sharePassport),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
