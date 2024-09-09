part of './instance.dart';

(String, List<String>) generateMember(String membersTableName) {
  String str = "INSERT INTO $membersTableName VALUES ";
  List<String> members = [];
  for (int i = 1; i <= 50; i++) {
    String id = nanoid();
    members.add('mock_member_id_$id');
    str +=
        "('mock_member_id_$id', 'Member $i', '${generateRandomMobileNumber()}')${i == 50 ? ';' : ','}";
  }
  return (str, members);
}

String generateRandomMobileNumber() {
  final random = Random();
  String number = '';
  for (int i = 0; i < 10; i++) {
    number += random.nextInt(9).toString();
  }
  return number;
}

List<String> getRandomMembers(List<String> members, int count) {
  if (count > members.length) {
    throw ArgumentError('Count cannot be greater than the list length');
  }

  final random = Random();
  final selectedMembers = <String>[];

  while (selectedMembers.length < count) {
    final randomIndex = random.nextInt(members.length);
    final randomString = members[randomIndex];
    if (!selectedMembers.contains(randomString)) {
      selectedMembers.add(randomString);
    }
  }

  return selectedMembers;
}

DateTime generateRandomDateFromPastTwoYears() {
  final now = DateTime.now();
  final twoYearsAgo = now.subtract(const Duration(days: 365 * 2));

  final random = Random();
  final randomDays = random.nextInt((now.difference(twoYearsAgo).inDays).abs());

  return twoYearsAgo.add(Duration(days: randomDays));
}

class RsalData {
  String rsalId;
  String rsalName;
  double rsalPrincipalAmount;
  int totalMonths;
  String createdAt;
  String status;
  List<String> memberIds;
  Map<int, List<String>> paidMembersByMonth;
  List<(String, int, double, int)> monthEMIInfo;
  String addMonthlyPaymentInfo;
  RsalData({
    required this.rsalId,
    required this.rsalName,
    required this.rsalPrincipalAmount,
    required this.totalMonths,
    required this.createdAt,
    required this.status,
    required this.memberIds,
    required this.paidMembersByMonth,
    required this.monthEMIInfo,
    required this.addMonthlyPaymentInfo,
  });

  List<String> getRawQueriesList(
    String rsalTableName,
    String rsalMembersTableName,
    String monthEmiTableName,
    String paymentTableName,
  ) {
    var queries = <String>[];
    queries.add(
        "INSERT INTO $rsalTableName VALUES ('$rsalId', '$rsalName', '$rsalPrincipalAmount', $totalMonths, '$createdAt', '$status');");

    queries.add(
        "INSERT INTO $rsalMembersTableName VALUES ${memberIds.map((memberId) => "('$rsalId', '$memberId')").join(",")};");

    if (monthEMIInfo.isNotEmpty) {
      queries.add(
          "INSERT INTO $monthEmiTableName VALUES ${monthEMIInfo.map((info) => "('$rsalId', '${info.$1}', ${info.$2}, ${info.$3}, ${info.$4})").join(",")};");
    }

    if (addMonthlyPaymentInfo.isNotEmpty) {
      queries.add(
          "INSERT INTO $paymentTableName VALUES ${addMonthlyPaymentInfo.replaceAll('),', '),')};");
    }

    return queries;
  }

  String getRawQueriesTerminal() {
    return '''
-- ADD RSAL GROUP
INSERT INTO rsals 
    VALUES ('$rsalId', '$rsalName', '$rsalPrincipalAmount', $totalMonths, '$createdAt', '$status'); 
      
-- ADD MEMBER TO RSAL GROUP
INSERT INTO rsals_members 
    VALUES ${memberIds.map((memberId) => "('$rsalId', '$memberId')").join(",\n           ")};
      
-- ADD MONTH PAYMENT INFO
INSERT INTO month_informations 
    VALUES ${monthEMIInfo.map((info) => "('$rsalId', '${info.$1}', ${info.$2}, ${info.$3}, ${info.$4})").join(",\n           ")}; 
      
-- ADD MEMBER MONTHLY PAYMENT INFO
INSERT INTO monthly_payments 
    VALUES ${addMonthlyPaymentInfo.replaceAll('),', '),\n           ')};
    ''';
  }

  @override
  String toString() {
    return '''
    RsalData {
      rsalId: $rsalId,
      rsalName: $rsalName,
      rsalPrincipalAmount: $rsalPrincipalAmount,
      totalMonths: $totalMonths,
      createdAt: $createdAt,
      status: $status,
      memberIds: ${memberIds.join(', ')},
      paidMembersByMonth: ${paidMembersByMonth.toString()},
      monthEMIInfo: ${monthEMIInfo.toString()}
      }, 
    ''';
  }
}

RsalData generateRSAL(
    double rsalPrincipalAmount, String rsalStatus, List<String> memberIds) {
  var queries = RsalData(
    rsalId: '',
    rsalName: '',
    rsalPrincipalAmount: rsalPrincipalAmount,
    totalMonths: 16,
    createdAt: generateRandomDateFromPastTwoYears().toString(),
    status: rsalStatus,
    memberIds: getRandomMembers(memberIds, 16),
    paidMembersByMonth: {},
    monthEMIInfo: [],
    addMonthlyPaymentInfo: "",
  );

  // GENERATE INSERT RSAL QUERY
  String id = nanoid();
  queries.rsalId = "mock_rsal_id_$id";
  queries.rsalName = "Rsal ${id.substring(0, 5)}";
  queries.status = rsalStatus;

  int completeMonth = 0;
  if (rsalStatus == "RUNNING") {
    completeMonth = (Random().nextDouble() * (queries.totalMonths - 1)).ceil();
  } else if (rsalStatus == "COMPLETED") {
    completeMonth = queries.totalMonths;
  }

  // GENERATE MONTH AND PAYMENT INFO
  final memberAlreadyTakenLoanList = <String>[];
  for (int month = 1; month <= completeMonth; month++) {
    final memberWhoCanTakeTheLoan = queries.memberIds
        .where((id) => !memberAlreadyTakenLoanList.contains(id))
        .toList();
    final memberIdTakingLoan = memberWhoCanTakeTheLoan[
        Random().nextInt(memberWhoCanTakeTheLoan.length)];
    memberAlreadyTakenLoanList.add(memberIdTakingLoan);
    double percentage =
        [1.0, 1.2, 1.25, 1.5, 1.75, 1.8, 2.0][Random().nextInt(7)];
    int emi = getMonthEMI(rsalPrincipalAmount, month, percentage).ceil();
    queries.paidMembersByMonth[month] = [];

    int getPaidEMI(String memberId) {
      if (Random().nextDouble() < 0.99) return emi;
      queries.paidMembersByMonth[month]!.add(memberId);
      return (emi * Random().nextDouble()).ceil();
    }

    queries.monthEMIInfo.add((memberIdTakingLoan, month, percentage, emi));
    String paymentQuery = queries.memberIds
        .map((memberId) =>
            "('mock_rsal_id_$id', '$memberId', $month, ${getPaidEMI(memberId)})")
        .join(',');
    queries.addMonthlyPaymentInfo +=
        paymentQuery + ((month == completeMonth) ? "" : ",");
  }
  return queries;
}
