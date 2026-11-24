import 'package:supabase_flutter/supabase_flutter.dart';

/// What a payment is for. Prices are decided by the server, never by the app.
enum PaymentType {
  proUpgrade('PRO_UPGRADE'),
  agreementGeneration('AGREEMENT_GENERATION');

  final String code;
  const PaymentType(this.code);
}

enum MobileMoneyProvider {
  mtn('MTN'),
  orange('ORANGE');

  final String code;
  const MobileMoneyProvider(this.code);
}

/// Result returned by the `payments` Edge Function.
class PaymentStatus {
  final String reference;
  final String status; // pending | success | failed | cancelled
  final String? message;
  const PaymentStatus(this.reference, this.status, [this.message]);

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
}

class PaymentException implements Exception {
  final String code;
  PaymentException(this.code);
  @override
  String toString() => code;
}

/// Centralized payment client. All MeSomb calls and verification happen in the
/// `payments` Edge Function; this class only starts a request and asks for its status.
class PaymentService {
  static FunctionsClient get _fn => Supabase.instance.client.functions;

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    try {
      final res = await _fn.invoke('payments', body: body);
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      if (data['error'] != null) throw PaymentException(data['error'].toString());
      return data;
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map && details['error'] != null ? details['error'].toString() : 'PAYMENT_UNAVAILABLE';
      throw PaymentException(code);
    }
  }

  static Future<PaymentStatus> initiate({
    required PaymentType type,
    required MobileMoneyProvider provider,
    required String phone,
    String? targetId,
  }) async {
    final d = await _call({
      'action': 'initiate',
      'type': type.code,
      'provider': provider.code,
      'phone': phone,
      if (targetId != null) 'target_id': targetId,
    });
    return PaymentStatus(d['reference'], d['status'], d['message']);
  }

  static Future<PaymentStatus> verify(String reference) async {
    final d = await _call({'action': 'verify', 'reference': reference});
    return PaymentStatus(d['reference'], d['status'], d['message']);
  }
}
