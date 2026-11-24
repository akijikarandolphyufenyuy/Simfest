import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/session_prefs.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../providers/agreements_provider.dart';
import 'agreement_detail_screen.dart';

/// Landing page for a collaborator invitation link: /invite/<token>
class InviteScreen extends StatefulWidget {
  final String token;
  const InviteScreen({super.key, required this.token});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  String? _error;
  bool _working = false;

  bool get _signedIn => Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    savePendingInvite(widget.token);
    if (_signedIn) WidgetsBinding.instance.addPostFrameCallback((_) => _claim());
  }

  Future<void> _claim() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final id = await claimInvite(widget.token);
      await takePendingInvite();
      if (!mounted) return;
      context.go('/home');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreementId: id)));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.handshake_rounded, color: AppColors.teal, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.inviteTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                    const SizedBox(height: 8),
                    Text(_signedIn ? l10n.inviteOpening : l10n.inviteSignInPrompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.5)),
                    const SizedBox(height: 22),
                    if (_error != null) ...[
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 14),
                    ],
                    if (_signedIn)
                      ElevatedButton(
                        onPressed: _working ? null : _claim,
                        child: _working
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                            : Text(l10n.openAgreement),
                      )
                    else ...[
                      ElevatedButton(onPressed: () => context.go('/register'), child: Text(l10n.register)),
                      const SizedBox(height: 10),
                      OutlinedButton(onPressed: () => context.go('/login'), child: Text(l10n.signIn)),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
