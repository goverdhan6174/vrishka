class RsalEmi {
  final String rsalId;
  final String memberId;
  final num percentage;
  final num emi;
  final int month;

  RsalEmi({
    required this.rsalId,
    required this.memberId,
    required this.percentage,
    required this.emi,
    required this.month,
  });

  // Convert a RsalEmi into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'rsal_id': rsalId,
      'member_id': memberId,
      'percentage': percentage,
      'emi': emi,
      'month': month,
    };
  }

  // Convert a Map into a RsalEmi. This is useful for fetching from the database.
  factory RsalEmi.fromMap(Map<String, dynamic> map) {
    return RsalEmi(
      rsalId: map['rsal_id'],
      memberId: map['member_id'],
      percentage: map['percentage'],
      month: map['month'],
      emi: map['emi'],
    );
  }
}
