import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../passport/models/passport.dart';
import '../models/opportunity.dart';

class OpportunityCard extends ConsumerWidget {
  final Opportunity opportunity;
  final VoidCallback onTap;
  final Widget? badge;
  const OpportunityCard({super.key, required this.opportunity, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final o = opportunity;
    final owner = ref.watch(publicPassportByUserProvider(o.ownerId)).whenOrNull(data: (p) => p);
    final count = ref.watch(applicationCountProvider(o.id)).whenOrNull(data: (c) => c);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                  backgroundImage: owner?.photoUrl != null ? NetworkImage(owner!.photoUrl!) : null,
                  child: owner?.photoUrl == null
                      ? Text((owner?.stageName ?? '?').characters.first.toUpperCase(),
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(owner?.stageName ?? '…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy, fontSize: 13)),
                    Text(timeAgo(l10n, o.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                  ]),
                ),
                if (badge != null) badge!,
                if (!o.isOpen) _Pill(l10n.statusClosed, AppColors.mutedText),
              ]),
              const SizedBox(height: 12),
              Text(o.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              const SizedBox(height: 4),
              Text(o.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.mutedText, height: 1.35)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final r in o.requiredRoles.take(3)) _Pill(passportRoleLabel(l10n, r), AppColors.deepNavy, filled: true),
                _Pill(arrangementLabel(l10n, o.collaborationType), AppColors.teal),
                _Pill(opportunityCategoryLabel(l10n, o.category), AppColors.mutedText),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Icon(o.isRemote ? Icons.wifi_rounded : Icons.place_outlined, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [if (o.location?.isNotEmpty ?? false) o.location!, if (o.isRemote) l10n.remoteOk].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                ),
                if (count != null)
                  Text(l10n.applicationsCount(count),
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  const _Pill(this.text, this.color, {this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
      );
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (status) {
      'accepted' => AppColors.success,
      'shortlisted' => AppColors.teal,
      'under_review' => Colors.indigo,
      'rejected' || 'withdrawn' => AppColors.mutedText,
      _ => Colors.orange,
    };
    return _Pill(applicationStatusLabel(l10n, status), color);
  }
}
