import 'package:flutter/material.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:vriksha/models/member.dart';

class CreateRsalPage extends StatefulWidget {
  final String? rsalId;

  const CreateRsalPage({super.key, this.rsalId});

  @override
  State<CreateRsalPage> createState() => _CreateRsalPageState();
}

class _CreateRsalPageState extends State<CreateRsalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _principalAmountController = TextEditingController();
  final _durationController = TextEditingController();
  String _status = 'RUNNING';
  List<Member> _members = [];
  List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    if (widget.rsalId != null) {
      _loadRsalData(widget.rsalId!);
    }
  }

  Future<void> _loadMembers() async {
    List<Member> members = await DB.getMembers();
    setState(() {
      _members = members;
    });
  }

  Future<void> _loadRsalData(String rsalId) async {
    Rsal? rsal = await DB.getRsal(rsalId);
    if (rsal == null) return;
    setState(() {
      _nameController.text = rsal.name;
      _principalAmountController.text = rsal.principalAmount.toString();
      _durationController.text = rsal.duration.toString();
      _status = rsal.status;
      _selectedMemberIds = rsal.memberIds;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalAmountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedMemberIds.length >= 2) {
      if (widget.rsalId == null) {
        await DB.createRsal(Rsal(
          name: _nameController.text,
          principalAmount: int.parse(_principalAmountController.text),
          duration: int.parse(_durationController.text),
          createDate: DateTime.now(),
          status: _status,
          memberIds: _selectedMemberIds.toList(),
        ));
      } else {
        await DB.updateRsal(Rsal.fromMap({
          "id": widget.rsalId,
          "name": _nameController.text,
          "principal_amount": int.parse(_principalAmountController.text),
          "duration": int.parse(_durationController.text),
          "created_at": DateTime.now().toIso8601String(),
          "status": _status,
          "memberIds": _selectedMemberIds.toList()
        }));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RSAL Created/Updated Successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 members.')),
      );
    }
  }

  Future<void> _showMemberSelectionDialog() async {
    final List<String> selectedMembers = List.from(_selectedMemberIds);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Members'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: double.minPositive,
                child: ListView(
                  children: _members.map((member) {
                    return CheckboxListTile(
                      value: selectedMembers.contains(member.id),
                      title: Text(member.name),
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            if (value) {
                              selectedMembers.add(member.id);
                            } else {
                              selectedMembers.remove(member.id);
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedMembers.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least 2 members.'),
                    ),
                  );
                } else {
                  Navigator.pop(context, selectedMembers);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedMemberIds = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.rsalId == null ? 'Create' : "Update"} RSAL'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'RSAL Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the RSAL name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _principalAmountController,
                decoration:
                    const InputDecoration(labelText: 'Principal Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the principal amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration:
                    const InputDecoration(labelText: 'Duration (months)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['STALE', 'RUNNING']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Text(
                      'Select Members',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                  TextButton(
                    onPressed: _showMemberSelectionDialog,
                    child: const Text('Select Members'),
                  ),
                ],
              ),
              if (_selectedMemberIds.isNotEmpty && _members.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: _selectedMemberIds.map((id) {
                      final member = _members.firstWhere((m) => m.id == id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Chip(
                          label: Text(member.name),
                          onDeleted: () {
                            setState(() {
                              _selectedMemberIds.remove(id);
                            });
                          },
                          deleteIconColor:
                              Theme.of(context).chipTheme.backgroundColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child:
                    Text(widget.rsalId != null ? "Update RSAL" : 'Create RSAL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
