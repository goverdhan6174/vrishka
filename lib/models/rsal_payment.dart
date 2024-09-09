class RsalPayment {
  final String rsalId;
  final String memberId;
  final int month;
  final num paidAmount;

  RsalPayment({
    required this.rsalId,
    required this.memberId,
    required this.month,
    required this.paidAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'rsal_id': rsalId,
      'member_id': memberId,
      'month': month,
      'paid_amount': paidAmount,
    };
  }

  factory RsalPayment.fromMap(Map<String, dynamic> map) {
    return RsalPayment(
      rsalId: map['rsal_id'],
      memberId: map['member_id'],
      month: map['month'],
      paidAmount: map['paid_amount'],
    );
  }
}
