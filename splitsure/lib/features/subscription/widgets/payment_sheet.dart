import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/profile_provider.dart';
import '../models/subscription.dart';
import '../services/receipt_service.dart';

/// Mobile-money payment flow: choose MTN/Orange, enter number, approve on phone.
/// Returns true only when the server confirmed the payment with MeSomb.
Future<bool> showPaymentSheet(
  BuildContext context, {
  required PaymentType type,
  required int amountFcfa,
  required String title,
  String? targetId,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(type: type, amount: amountFcfa, title: title, targetId: targetId),
  );
  return ok == true;
}

enum _Stage { form, waiting, success, failed, stillPending }

class _PaymentSheet extends ConsumerStatefulWidget {
  final PaymentType type;
  final int amount;
  final String title;
  final String? targetId;
  const _PaymentSheet({required this.type, required this.amount, required this.title, this.targetId});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  MobileMoneyProvider _provider = MobileMoneyProvider.mtn;
  final _phone = TextEditingController();
  _Stage _stage = _Stage.form;
  String? _error;
  String? _reference;
  Timer? _poll;
  int _polls = 0;
  bool _busy = false;

  static const _pollEvery = Duration(seconds: 5);
  static const _maxPolls = 24; // ~2 minutes, then "still pending" with a manual re-check

  @override
  void initState() {
    super.initState();
    final phone = ref.read(profileProvider).whenOrNull(data: (p) => p?.phone) ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    _phone.text = digits.length >= 9 ? digits.substring(digits.length - 9) : digits;
    if (_phone.text.startsWith('69') || _phone.text.startsWith('655') || _phone.text.startsWith('656') ||
        _phone.text.startsWith('657') || _phone.text.startsWith('658') || _phone.text.startsWith('659')) {
      _provider = MobileMoneyProvider.orange;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    super.dispose();
  }

  String _amount(BuildContext context) =>
      AppLocalizations.of(context)!.amountFcfa(NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
          .format(widget.amount));

  String _message(AppLocalizations l10n, Object e) {
    final code = e is PaymentException ? e.code : '';
    return switch (code) {
      'INVALID_PHONE' => l10n.invalidCameroonPhone,
      'ALREADY_PRO' => l10n.alreadyPro,
      _ => l10n.paymentsUnavailable,
    };
  }

  Future<void> _pay() async {
    final l10n = AppLocalizations.of(context)!;
    if (!RegExp(r'^6\d{8}$').hasMatch(_phone.text.trim())) {
      setState(() => _error = l10n.invalidCameroonPhone);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await PaymentService.initiate(
          type: widget.type, provider: _provider, phone: _phone.text.trim(), targetId: widget.targetId);
      _reference = s.reference;
      _apply(s);
      if (s.isPending) _startPolling();
    } catch (e) {
      setState(() => _error = _message(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling() {
    _polls = 0;
    _poll?.cancel();
    _poll = Timer.periodic(_pollEvery, (_) => _check());
  }

  Future<void> _check({bool manual = false}) async {
    if (_reference == null) return;
    if (manual) setState(() => _busy = true);
    try {
      final s = await PaymentService.verify(_reference!);
      _polls++;
      if (!mounted) return;
      if (s.isPending && _polls >= _maxPolls) {
        _poll?.cancel();
        setState(() => _stage = _Stage.stillPending);
      } else {
        _apply(s);
      }
    } catch (_) {
      // Network hiccup: keep polling; the server state is the source of truth.
    } finally {
      if (mounted && manual) setState(() => _busy = false);
    }
  }

  Future<void> _receipt() async {
    setState(() => _busy = true);
    try {
      final tx = await fetchPaymentTransaction(_reference!);
      if (tx != null && mounted) await downloadReceipt(context, ref, tx);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _apply(PaymentStatus s) {
    if (!mounted) return;
    setState(() {
      if (s.isSuccess) {
        _poll?.cancel();
        _stage = _Stage.success;
        ref.invalidate(paymentHistoryProvider);
      } else if (s.isPending) {
        if (_stage != _Stage.stillPending) _stage = _Stage.waiting;
      } else {
        _poll?.cancel();
        _stage = _Stage.failed;
        ref.invalidate(paymentHistoryProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(key: ValueKey(_stage), child: _body(l10n)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) => switch (_stage) {
        _Stage.form => _form(l10n),
        _Stage.waiting => _status(
            icon: null,
            title: l10n.waitingForApproval,
            body: '${l10n.approveOnPhone(_amount(context))}\n\n${l10n.dialToApprove}',
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.close)),
            ],
          ),
        _Stage.stillPending => _status(
            icon: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 56),
            title: l10n.waitingForApproval,
            body: l10n.paymentStillPending,
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.close)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                onPressed: _busy ? null : () => _check(manual: true),
                child: Text(l10n.checkAgain),
              ),
            ],
          ),
        _Stage.success => _status(
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            title: l10n.paymentConfirmed,
            body: '${widget.title} · ${_amount(context)}',
            actions: [
              if (_reference != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                  ),
                  onPressed: _busy ? null : _receipt,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(l10n.downloadReceipt),
                ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        _Stage.failed => _status(
            icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 64),
            title: l10n.paymentNotCompleted,
            body: l10n.paymentFailedBody,
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.close)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                onPressed: () => setState(() {
                  _stage = _Stage.form;
                  _reference = null;
                }),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
      };

  Widget _form(AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.payWithMobileMoney,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 4),
      Text('${widget.title} · ${_amount(context)}',
          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
            child: _ProviderTile(
          label: l10n.mtnMomo,
          logoAsset: 'assets/images/subscrib/mtn.jpg',
          color: const Color(0xFFFFCC00),
          textColor: Colors.black,
          selected: _provider == MobileMoneyProvider.mtn,
          onTap: () => setState(() => _provider = MobileMoneyProvider.mtn),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _ProviderTile(
          label: l10n.orangeMoney,
          logoAsset: 'assets/images/subscrib/orange.png',
          color: const Color(0xFFFF7900),
          textColor: Colors.white,
          selected: _provider == MobileMoneyProvider.orange,
          onTap: () => setState(() => _provider = MobileMoneyProvider.orange),
        )),
      ]),
      const SizedBox(height: 16),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
        decoration: InputDecoration(
          labelText: l10n.mobileMoneyNumber,
          hintText: l10n.mobileMoneyNumberHint,
          prefixText: '+237 ',
          errorText: _error,
          errorMaxLines: 3,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _busy ? null : _pay,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(l10n.payAmount(_amount(context)), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l10n.cancel)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_rounded, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(l10n.securePaymentNote,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
        ),
      ]),
    ]);
  }

  Widget _status({Widget? icon, required String title, required String body, required List<Widget> actions}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Center(
        child: icon ??
            const SizedBox(
                width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.teal)),
      ),
      const SizedBox(height: 18),
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, height: 1.4)),
      const SizedBox(height: 20),
      // Wraps onto two lines on narrow phones instead of overflowing.
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: actions,
      ),
    ]);
  }
}

class _ProviderTile extends StatelessWidget {
  final String label;
  final String logoAsset;
  final Color color;
  final Color textColor;
  final bool selected;
  final VoidCallback onTap;
  const _ProviderTile({
    required this.label,
    required this.logoAsset,
    required this.color,
    required this.textColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(logoAsset, width: 44, height: 44, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: selected ? color : AppColors.deepNavy,
            ),
          ),
        ]),
      ),
    );
  }
}
