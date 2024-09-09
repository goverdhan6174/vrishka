class Payment {
  final String memberId;
  final num paidAmount;

  Payment({
    required this.memberId,
    this.paidAmount = 0,
  });

  Payment.fromMap(Map<String, Object?> map)
      : memberId = map['member_id'] as String,
        paidAmount = map['paid_amount'] as num;

  @override
  String toString() {
    return 'Payment(memberId: $memberId, paidAmount: $paidAmount)';
  }
}

class RsalMonthlyInfo {
  final String rsalId;
  final String memberId;
  final int month;
  final num percentage;
  final num emi;
  final List<Payment> payments;

  RsalMonthlyInfo({
    required this.rsalId,
    this.memberId = "",
    this.month = 1,
    this.percentage = 0,
    this.emi = 0,
    this.payments = const [],
  });

  RsalMonthlyInfo.fromMap(Map<String, dynamic> map)
      : rsalId = map['rsal_id'] as String,
        memberId = map['member_id'] as String,
        month = map['month'] as int,
        percentage = map['percentage'] as num,
        emi = map['emi'] as num,
        payments = ((map['payments'] as List<Map<String, dynamic>>)
            .map((paymentMap) => Payment.fromMap(paymentMap))).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RsalMonthlyInfo && rsalId == other.rsalId;

  @override
  int get hashCode => rsalId.hashCode;

  @override
  String toString() {
    return 'RsalMonthlyInfo(id: $rsalId, memberId: $memberId, payments: ${payments.length})';
  }
}
