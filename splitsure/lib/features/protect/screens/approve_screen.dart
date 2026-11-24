import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/auth_layout.dart';

/// Opened from the "Approve & sign" button in the invitation e-mail: /approve/<token>.
/// Works signed out — the one-time token proves the collaborator received the e-mail.
/// One tap approves; the server stamps a signature code that is printed on the document.
class ApproveScreen extends StatefulWidget {
  final String token;

  /// Opened from the witness e-mail's "Decline" link: ask to decline right away.
  final bool decline;
  const ApproveScreen({super.key, required this.token, this.decline = false});

  @override
  State<ApproveScreen> createState() => _ApproveScreenState();
}

class _ApproveScreenState extends State<ApproveScreen> {
  Map<String, dynamic>? _info;
  String? _error; // INVALID_LINK, LINK_EXPIRED, … or a message
  bool _loading = true;
  bool _signing = false;
  String? _code;
  String? _status;
  bool _already = false;
  bool _declined = false;

  bool get _isWitness => _info?['kind'] == 'witness';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    try {
      final res = await Supabase.instance.client.functions.invoke('agreement-emails', body: body);
      return (res.data as Map).cast<String, dynamic>();
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] != null) throw d['error'].toString();
      throw 'INVALID_LINK';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _call({'action': 'approval_info', 'token': widget.token});
      if (!mounted) return;
      setState(() {
        _info = info;
        if (info['state'] == 'signed') {
          _code = info['signature_code'];
          _status = info['agreement_status'];
          _already = true;
        } else if (info['state'] == 'declined') {
          _declined = true;
          _already = true;
        }
      });
      if (widget.decline && info['kind'] == 'witness' && info['state'] == 'open') {
        WidgetsBinding.instance.addPostFrameCallback((_) => _declineWitness());
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _declineWitness() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.witnessDeclineTitle),
        content: Text(l10n.witnessDeclineQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.decline, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) await _approve(response: 'declined');
  }

  Future<void> _approve({String? response}) async {
    setState(() => _signing = true);
    try {
      final r = await _call({
        'action': 'approve',
        'token': widget.token,
        if (response != null) 'response': response,
      });
      if (!mounted) return;
      setState(() {
        _code = r['signature_code'];
        _status = r['status'];
        _already = r['already'] == true;
        _declined = r['response'] == 'declined';
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    } else if (_declined) {
      body = _witnessDeclinedView(l10n);
    } else if (_code != null) {
      body = _signed(l10n);
    } else if (_error != null || _info?['state'] != 'open') {
      body = _problem(l10n, _error ?? _info?['state'] as String? ?? 'INVALID_LINK');
    } else {
      body = _review(l10n);
    }
    return AuthLayout(
      onBack: () => context.go('/welcome'),
      child: AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: body),
    );
  }

  Widget _review(AppLocalizations l10n) {
    final info = _info!;
    final me = (info['recipient'] as Map).cast<String, dynamic>();
    final parties = (info['parties'] as List).cast<Map>();
    return Column(key: const ValueKey('review'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FadeSlideIn(
        child: Text(_isWitness ? l10n.witnessApproveTitle : l10n.approveTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy, height: 1.2)),
      ),
      const SizedBox(height: 8),
      FadeSlideIn(
        delay: stagger(1),
        child: Text(
            _isWitness
                ? l10n.witnessApproveIntro(info['owner_name'] ?? '', info['song'] ?? '')
                : l10n.approveIntro(info['owner_name'] ?? '', info['song'] ?? ''),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5)),
      ),
      const SizedBox(height: 18),
      FadeSlideIn(
        delay: stagger(2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF142B4A), Color(0xFF0D9488)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${info['song']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${info['reference']} · v${info['version']}',
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                const SizedBox(height: 8),
                Text('${l10n.approveYourRole}: ${_isWitness ? l10n.witness : musicRoleLabel(l10n, '${me['role']}')}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            if (_isWitness)
              const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 36)
            else ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text(l10n.approveYourShare.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 10, letterSpacing: 1)),
                Text(_pct(me['share']),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
            ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 16),
      FadeSlideIn(
        delay: stagger(3),
        child: Text(l10n.approveParties.toUpperCase(),
            style:
                const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.teal)),
      ),
      const SizedBox(height: 6),
      FadeSlideIn(
        delay: stagger(3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: [
            for (var i = 0; i < parties.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
              _partyRow(l10n, parties[i].cast<String, dynamic>()),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 14),
      FadeSlideIn(
        delay: stagger(4),
        child: Text(_isWitness ? l10n.witnessApproveLegal : l10n.approveLegal,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.5)),
      ),
      const SizedBox(height: 16),
      FadeSlideIn(
        delay: stagger(5),
        child: ElevatedButton(
          onPressed: _signing ? null : _approve,
          child: _signing
              ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_isWitness ? Icons.how_to_reg_rounded : Icons.draw_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(_isWitness ? l10n.witnessConfirmButton : l10n.approveButton),
                ]),
        ),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _signing ? null : (_isWitness ? _declineWitness : _requestChanges),
        child: Text(_isWitness ? l10n.decline : l10n.approveChanges,
            style: TextStyle(
                color: _isWitness ? Colors.redAccent : AppColors.mutedText, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  /// Changes / decline need the full agreement view: go through the regular invitation (sign in).
  void _requestChanges() {
    final invite = _info?['invite_token'];
    context.go(invite != null ? '/invite/$invite' : '/login');
  }

  Widget _partyRow(AppLocalizations l10n, Map<String, dynamic> p) {
    final mine = p['is_recipient'] == true;
    return Container(
      color: mine ? AppColors.teal.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(p['signed'] == true ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18, color: p['signed'] == true ? AppColors.success : AppColors.cardBorder),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['name']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5, color: AppColors.deepNavy, fontWeight: mine ? FontWeight.w800 : FontWeight.w600)),
            Text(musicRoleLabel(l10n, '${p['role']}'),
                style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
          ]),
        ),
        Text(_pct(p['share']),
            style: const TextStyle(fontSize: 13.5, color: AppColors.deepNavy, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _signed(AppLocalizations l10n) {
    final complete = _status == 'accepted';
    return Column(key: const ValueKey('signed'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.teal, Color(0xFF12B8A6)]),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.white, size: 40),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(_isWitness ? l10n.witnessSignedTitle : (_already ? l10n.approveAlreadySigned : l10n.approveSignedTitle),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      Text(_isWitness ? l10n.witnessSignedBody : l10n.approveSignedBody,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal, width: 1.4),
        ),
        child: Column(children: [
          Text((_isWitness ? l10n.witnessCode : l10n.signatureCode).toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, letterSpacing: 1.2, color: AppColors.teal, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: SelectableText(_code!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).copyButtonLabel,
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.teal),
              onPressed: () => Clipboard.setData(ClipboardData(text: _code!)),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(complete ? Icons.celebration_rounded : Icons.hourglass_top_rounded,
            size: 16, color: complete ? AppColors.success : AppColors.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(complete ? l10n.approveAllSigned : l10n.approveWaitingOthers,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  color: complete ? AppColors.success : AppColors.mutedText,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => context.go(Supabase.instance.client.auth.currentUser != null ? '/home' : '/welcome'),
        child: Text(l10n.approveOpenApp),
      ),
    ]);
  }

  Widget _witnessDeclinedView(AppLocalizations l10n) {
    return Column(key: const ValueKey('declined'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.do_not_disturb_on_rounded, size: 56, color: Colors.redAccent),
      const SizedBox(height: 12),
      Text(l10n.witnessDeclinedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      Text(l10n.witnessDeclinedBody,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => context.go(Supabase.instance.client.auth.currentUser != null ? '/home' : '/welcome'),
        child: Text(l10n.approveOpenApp),
      ),
    ]);
  }

  Widget _problem(AppLocalizations l10n, String code) {
    final msg = switch (code) {
      'expired' || 'LINK_EXPIRED' => l10n.approveExpired,
      'newer_version' || 'NEWER_VERSION' => l10n.approveNewerVersion,
      'closed' || 'NOT_OPEN' || 'used' || 'LINK_USED' => l10n.approveClosed,
      _ => l10n.approveInvalid,
    };
    return Column(key: const ValueKey('problem'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.link_off_rounded, size: 52, color: AppColors.mutedText),
      const SizedBox(height: 12),
      Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.deepNavy, fontWeight: FontWeight.w600, height: 1.5)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () => context.go(Supabase.instance.client.auth.currentUser != null ? '/home' : '/welcome'),
        child: Text(l10n.approveOpenApp),
      ),
    ]);
  }

  static String _pct(dynamic n) {
    final v = (n as num?)?.toDouble() ?? 0;
    return '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%';
  }
}
