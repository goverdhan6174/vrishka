import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vriksha/components/dialogs/edit_payment_dialog.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/helpers/current_format.dart';
import 'package:vriksha/helpers/ordinal_suffix.dart';
import 'package:vriksha/models/member_rsal_info.dart';
import 'package:vriksha/pages/rsal/detail/rsal_detail_page.dart';

class MemberRsalCard extends StatefulWidget {
  final String rsalId;
  final String memberId;
  final bool showFilteredMembers;

  const MemberRsalCard({
    super.key,
    required this.rsalId,
    required this.memberId,
    this.showFilteredMembers = false,
  });

  @override
  State<MemberRsalCard> createState() => _MemberRsalCardState();
}

class _MemberRsalCardState extends State<MemberRsalCard> {
  void _showEditPaymentDialog(String memberId, int month) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPaymentDialog(
          rsalId: widget.rsalId,
          memberId: memberId,
          month: month,
          onSave: () {
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<MemberRsalInfo>(
          future: DB.getMemberRsalInfo(widget.rsalId, widget.memberId),
          builder: (context, membersSnapshot) {
            if (membersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (membersSnapshot.hasError) {
              return Center(child: Text('Error: ${membersSnapshot.error}'));
            }

            final rsalMembers = membersSnapshot.data!;
            final memberPayments = rsalMembers.memberPayments.where((payment) {
              if (!widget.showFilteredMembers) return true;
              if (payment.paidAmount < payment.emi) return true;
              return false;
            }).toList();
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rsalMembers.rsal.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            indianRupeeFormat(rsalMembers.rsal.principalAmount),
                            style: const TextStyle(fontSize: 20),
                          ),
                          Text(
                            'Duration: ${rsalMembers.rsal.duration}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Created On: ${DateFormat('dd/MM/yyyy').format((rsalMembers.rsal.createDate))}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Status: ${rsalMembers.rsal.status}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: rsalMembers.rsal.status.toUpperCase() ==
                                      "COMPLETED"
                                  ? Colors.amber
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RsalDetailPage(rsalId: rsalMembers.rsal.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: memberPayments.length,
                    itemBuilder: (context, index) {
                      final member = memberPayments[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                          border: Border.all(
                            width: 1,
                            color: Colors.blueGrey,
                          ),
                          color: member.loanMemberId == widget.memberId
                              ? Colors.deepPurple.shade100
                              : Theme.of(context).chipTheme.backgroundColor,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextButton(
                                onPressed: member.paidAmount >= member.emi
                                    ? null
                                    : () {
                                        _showEditPaymentDialog(
                                            widget.memberId, member.month);
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent.shade700,
                                  disabledForegroundColor:
                                      Colors.greenAccent.shade700,
                                ),
                                child: Text(
                                  'Paid: ${indianRupeeFormat(member.paidAmount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: member.percentage == 0
                                        ? Colors.black
                                        : member.paidAmount < member.emi
                                            ? Colors.redAccent.shade700
                                            : Colors.greenAccent.shade700,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${ordinalSuffix(member.month)} Month',
                                  ),
                                  Text(
                                    'Emi: ${indianRupeeFormat(member.emi)}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
