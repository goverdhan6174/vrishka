import 'package:vriksha/models/rsal.dart';

class MemberPayment {
  final String loanMemberId;
  final num emi;
  final num percentage;
  final int month;
  final num paidAmount;

  MemberPayment({
    required this.loanMemberId,
    this.emi = 0,
    this.percentage = 0,
    this.month = 0,
    this.paidAmount = 0,
  });

  MemberPayment.fromMap(Map<String, Object?> map)
      : loanMemberId = map['member_id'] as String,
        emi = map['emi'] as num,
        percentage = map['percentage'] as num,
        month = map['month'] as int,
        paidAmount = map['paid_amount'] as num;

  @override
  String toString() {
    return 'MemberPayment(loanMemberId: $loanMemberId, paidAmount/emi: $paidAmount/$emi, month: $month)';
  }
}

class MemberRsalInfo {
  final Rsal rsal;
  final List<MemberPayment> memberPayments;

  MemberRsalInfo({
    required this.rsal,
    this.memberPayments = const [],
  });

  MemberRsalInfo.fromMap(Map<String, dynamic> map)
      : rsal = Rsal.fromMap(map['rsal']),
        memberPayments = ((map['memberPayments'] as List<Map<String, dynamic>>)
            .map((paymentMap) => MemberPayment.fromMap(paymentMap))).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberRsalInfo && rsal.id == other.rsal.id;

  @override
  int get hashCode => rsal.hashCode;

  @override
  String toString() {
    return 'MemberRsalInfo(rsal: $rsal, memberPayments: $memberPayments)';
  }
}
