import 'package:flutter/material.dart';
import 'package:vriksha/components/dialogs/edit_emi_dialog.dart';
import 'package:vriksha/components/dialogs/edit_payment_dialog.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/helpers/current_format.dart';
import 'package:vriksha/helpers/ordinal_suffix.dart';
import 'package:vriksha/models/member.dart';
import 'package:vriksha/models/rsal_monthly_info.dart';
import 'package:vriksha/pages/member/detail/member_detail_page.dart';

class MonthInfoCard extends StatefulWidget {
  final String rsalId;
  final int month;
  final bool showFilteredMembers;

  const MonthInfoCard({
    super.key,
    required this.rsalId,
    required this.month,
    this.showFilteredMembers = false,
  });

  @override
  State<MonthInfoCard> createState() => _MonthInfoCardState();
}

class _MonthInfoCardState extends State<MonthInfoCard> {
  Future<RsalMonthlyInfo>? _rsalMonthlyInfo;
  Future<List<Member>>? _rsalMembers;

  void _showEditEmiDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditEmiDialog(rsalId: widget.rsalId, month: widget.month);
      },
    );
  }

  void _showEditPaymentDialog(String memberId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPaymentDialog(
          rsalId: widget.rsalId,
          memberId: memberId,
          month: widget.month,
          onSave: () {
            setState(() {});
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _rsalMembers = DB.getRsalMembers(widget.rsalId);
    _rsalMonthlyInfo =
        DB.getRsalMonthAndPaymentInfo(widget.rsalId, widget.month);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Member>>(
            future: _rsalMembers,
            builder: (context, membersSnapshot) {
              if (membersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (membersSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${membersSnapshot.error}'),
                );
              }

              return FutureBuilder<RsalMonthlyInfo>(
                future: _rsalMonthlyInfo,
                builder: (context, monthInfoSnapshot) {
                  if (monthInfoSnapshot.hasData) {
                    final members = membersSnapshot.data!;
                    final info = monthInfoSnapshot.data!;
                    final filteredMembers = members.where((member) {
                      if (!widget.showFilteredMembers) return true;
                      final payment = info.payments.firstWhere(
                          (payment) => payment.memberId == member.id,
                          orElse: () => Payment(memberId: member.id));
                      if (payment.paidAmount < info.emi) return true;
                      return false;
                    }).toList();
                    final loanMember = members.firstWhere(
                        (member) => member.id == info.memberId,
                        orElse: () => Member(mobile: "", name: ""));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${ordinalSuffix(info.month)} Month',
                                    ),
                                    Text(
                                      '${info.percentage}%',
                                      style: const TextStyle(
                                        fontSize: 48.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Amount: ${indianRupeeFormat(info.emi)}',
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      loanMember.name != ''
                                          ? '${loanMember.name} took the loan.'
                                          : 'No member took the loan yet.',
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                  flex: 1,
                                  child: info.emi > 0
                                      ? const SizedBox(
                                          width: 0,
                                          height: 0,
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditEmiDialog();
                                          },
                                        )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final member = filteredMembers[index];
                              final payment = info.payments.firstWhere(
                                  (payment) => payment.memberId == member.id,
                                  orElse: () => Payment(memberId: member.id));

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 4.0,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.blueGrey,
                                  ),
                                  color: member.id == info.memberId
                                      ? Colors.deepPurple.shade100
                                      : Theme.of(context)
                                          .chipTheme
                                          .backgroundColor,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MemberDetailPage(
                                              member: member,
                                            ),
                                          ),
                                        )
                                      },
                                      child: Text(member.name),
                                    ),
                                    TextButton(
                                      onPressed: payment.paidAmount == info.emi
                                          ? null
                                          : () {
                                              _showEditPaymentDialog(member.id);
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Colors.redAccent.shade700,
                                        disabledForegroundColor:
                                            Colors.greenAccent.shade700,
                                      ),
                                      child: Text(
                                        indianRupeeFormat(payment.paidAmount),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              );
            }),
      ),
    );
  }
}
