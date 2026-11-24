import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/passport.dart';
import 'passport_view.dart';

/// Shows another member's public Music Passport in a sheet (opportunity owner, applicant…).
Future<void> showPassportSheet(BuildContext context, String userId, {List<Widget> Function(BuildContext)? actions}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Consumer(builder: (ctx, ref, _) {
        final l10n = AppLocalizations.of(ctx)!;
        final async = ref.watch(publicPassportByUserProvider(userId));
        final portfolio =
            ref.watch(publicPortfolioProvider(userId)).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[];
        return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 10, 16, 30), children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: async.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
                error: (e, _) => Text('$e'),
                data: (p) => p == null
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(l10n.passportNotFound, textAlign: TextAlign.center),
                      )
                    : PassportView(passport: p, portfolio: portfolio, actions: actions?.call(ctx) ?? const []),
              ),
            ),
          ),
        ]);
      }),
    ),
  );
}
