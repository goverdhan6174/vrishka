import 'package:flutter/material.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/helpers/current_format.dart';
import 'package:vriksha/helpers/generate_month_emi.dart';
import 'package:vriksha/helpers/ordinal_suffix.dart';
import 'package:vriksha/models/member.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:vriksha/models/rsal_emi.dart';

class EditEmiDialog extends StatefulWidget {
  final String rsalId;
  final int month;
  const EditEmiDialog({
    super.key,
    required this.rsalId,
    required this.month,
  });

  @override
  State<EditEmiDialog> createState() => _EditEmiDialogState();
}

class _EditEmiDialogState extends State<EditEmiDialog> {
  final _dialogFormKey = GlobalKey<FormState>();
  final _percentController = TextEditingController();
  String _selectedMemberId = "";
  num calculatedEmi = 0.0;
  Rsal? rsal;

  @override
  void initState() {
    super.initState();
    _loadRsalData(widget.rsalId, widget.month);
  }

  Future<void> _loadRsalData(String rsalId, int month) async {
    rsal = await DB.getRsal(rsalId);
    RsalEmi? rsalEmiInfo = await DB.getRsalMonthInfo(rsalId, month);
    if (rsalEmiInfo == null) return;
    setState(() {
      _percentController.text = rsalEmiInfo.percentage.toString();
      _selectedMemberId = rsalEmiInfo.memberId;
      calculatedEmi = rsalEmiInfo.emi;
    });
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_dialogFormKey.currentState!.validate()) {
      final newRsalEmi = RsalEmi(
        memberId: _selectedMemberId,
        emi: calculatedEmi,
        month: widget.month,
        rsalId: widget.rsalId,
        percentage: double.parse(_percentController.text),
      );

      await DB.insertRsalEmi(newRsalEmi);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member Created Successfully!')),
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
        '${ordinalSuffix(widget.month)} Month',
      ),
      content: SizedBox(
        width: cardWidth > 350 ? 350 : cardWidth,
        child: Form(
          key: _dialogFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<Member>>(
                future: DB.getRsalMembers(widget.rsalId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DropdownButtonFormField<String>(
                      value: _selectedMemberId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a member',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: "",
                          child: Text(
                            "None",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        ...snapshot.data!.map((user) {
                          return DropdownMenuItem<String>(
                            value: user.id,
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0,
                              ),
                            ),
                          );
                        })
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMemberId = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a Member';
                        }
                        return null;
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
              spacer,
              TextFormField(
                controller: _percentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter percentage',
                ),
                onChanged: (String? percentage) {
                  if (percentage == null || rsal == null) return;
                  double percent = 0.0;
                  if (double.tryParse(percentage) != null) {
                    percent = double.parse(percentage);
                  }
                  setState(() {
                    calculatedEmi = getMonthEMI(
                      double.parse(rsal!.principalAmount.toString()),
                      widget.month,
                      percent,
                    );
                  });
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null) {
                    return 'Please enter a number';
                  }
                  if (num.parse(value) < 1 || num.parse(value) > 2) {
                    return "Percent should greater than 1 and smaller than 2";
                  }
                  return null;
                },
              ),
              spacer,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calculated Emi:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    indianRupeeFormat(calculatedEmi).toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
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
