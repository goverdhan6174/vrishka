import 'package:flutter/material.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/helpers/current_format.dart';
import 'package:vriksha/helpers/ordinal_suffix.dart';
import 'package:vriksha/models/member.dart';
import 'package:vriksha/models/rsal_emi.dart';
import 'package:vriksha/models/rsal_payment.dart';

class EditPaymentDialog extends StatefulWidget {
  final String rsalId;
  final String memberId;
  final int month;
  final Function onSave;

  const EditPaymentDialog({
    super.key,
    required this.rsalId,
    required this.memberId,
    required this.month,
    required this.onSave,
  });

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final _dialogFormKey = GlobalKey<FormState>();
  final _paidAmountController = TextEditingController();
  num emiAmount = 0.0;
  num leftAmount = 0.0;
  num enteredAmount = 0.0;
  Member? member;
  RsalPayment? rsalPayment;

  @override
  void initState() {
    super.initState();
    _loadPaymentData(widget.rsalId, widget.memberId, widget.month);
  }

  Future<void> _loadPaymentData(
      String rsalId, String memberId, int month) async {
    member = await DB.getMember(memberId);
    RsalEmi? rsalEmi = await DB.getRsalMonthInfo(rsalId, month);
    rsalPayment = await DB.getRsalPayment(rsalId, memberId, month);
    setState(() {
      emiAmount = rsalEmi?.emi ?? 0;
      leftAmount = (rsalEmi?.emi ?? 0) - (rsalPayment?.paidAmount ?? 0);
    });
    widget.onSave();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_dialogFormKey.currentState!.validate()) {
      final newRsalPayment = RsalPayment(
        rsalId: widget.rsalId,
        memberId: widget.memberId,
        month: widget.month,
        paidAmount: double.parse(_paidAmountController.text),
      );

      await DB.createOrUpdateRsalPayment(newRsalPayment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Updated Successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var cardWidth = MediaQuery.of(context).size.width * 0.9;
    var spacer = const SizedBox(height: 20);
    return AlertDialog(
      title: Text(
        '${member?.name} - ${ordinalSuffix(widget.month)} month',
      ),
      content: SizedBox(
        width: cardWidth > 350 ? 350 : cardWidth,
        child: Form(
          key: _dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                ),
                onChanged: (String? value) {
                  final isValidAmount = !(value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null);
                  setState(() {
                    enteredAmount = isValidAmount ? double.parse(value) : 0;
                  });
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null) {
                    return 'Please enter a number';
                  }
                  final amount = double.parse(value);
                  if (amount < 0) {
                    return "Amount can't be negative";
                  }
                  if (amount > emiAmount) {
                    return "Amount can't be greater than EMI";
                  }
                  if (amount > leftAmount) {
                    return "Can't add more amount than required";
                  }
                  return null;
                },
              ),
              spacer,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Left Amount:',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  Text(
                    indianRupeeFormat(leftAmount).toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.grey.shade700,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pay/EMI:',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  RichText(
                    text: TextSpan(
                      text: indianRupeeFormat(leftAmount - enteredAmount)
                          .toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: leftAmount > 0
                            ? Colors.redAccent.shade700
                            : Colors.greenAccent.shade700,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                            text:
                                ' / ${indianRupeeFormat(emiAmount).toString()}',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: _submitForm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
