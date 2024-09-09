import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:intl/intl.dart';

class SearchRsalPage extends StatefulWidget {
  final Function(List<Rsal>) updateRsals;
  final Function() clearRsals;
  const SearchRsalPage({
    super.key,
    required this.updateRsals,
    required this.clearRsals,
  });

  @override
  State<SearchRsalPage> createState() => _SearchRsalPageState();
}

class _SearchRsalPageState extends State<SearchRsalPage> {
  DateTime? selectedDate;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _createdDateController = TextEditingController(text: null);
  final _endDateController = TextEditingController();
  bool isFetching = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _createdDateController.text = DateFormat('dd-MM').format(picked);
    }
  }

  Future<void> _searchRsals() async {
    setState(() {
      isFetching = true;
    });
    String? name = _nameController.text.isEmpty ? null : _nameController.text;
    DateTime? createdDate = _createdDateController.text.isEmpty
        ? null
        : DateFormat('dd-MM').parse(_createdDateController.text);
    DateTime? endDate = _endDateController.text.isEmpty
        ? null
        : DateFormat('dd-MM').parse(_endDateController.text);

    final rsals = await DB.searchRsals(name, createdDate, endDate);
    widget.updateRsals(rsals);
    setState(() {
      isFetching = false;
    });
  }

  void _clearFields() {
    _nameController.clear();
    _createdDateController.clear();
    _endDateController.clear();
    widget.clearRsals();
  }

  Future<void> _generateMockData() async {
    setState(() {
      isFetching = true;
    });
    await DB.generateMockData();
    setState(() {
      isFetching = false;
    });
  }

  Future<void> _deleteMockData() async {
    setState(() {
      isFetching = true;
    });
    await DB.deleteMockData();
    setState(() {
      isFetching = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _createdDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width * 0.3;
    width = width > 250 ? width : 250;

    return ExpansionTile(
      title: const Text('Search RSAL'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey, width: 1.0),
                          ),
                          hintText: 'RSAL NAME',
                          labelText: 'Enter RSAL name',
                        ),
                        controller: _nameController,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: TextFormField(
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blueGrey, width: 1.0),
                          ),
                          hintText: 'Enter Date (DD-MM-YYYY)',
                          labelText: 'Created Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: _createdDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))
                        ],
                      ),
                    ),
                    // SizedBox(
                    //   width: width,
                    //   child: TextFormField(
                    //     decoration: const InputDecoration(
                    //       focusedBorder: OutlineInputBorder(
                    //         borderSide:
                    //             BorderSide(color: Colors.grey, width: 1.0),
                    //       ),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderSide:
                    //             BorderSide(color: Colors.blueGrey, width: 1.0),
                    //       ),
                    //       hintText: 'Enter Date (DD-MM-YYYY)',
                    //       labelText: 'End Date',
                    //     ),
                    //     controller: _endDateController,
                    //     keyboardType: TextInputType.datetime,
                    //     inputFormatters: [
                    //       FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: isFetching ? null : _searchRsals,
                        child: const Text('Search'),
                      ),
                      ElevatedButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent.shade700,
                        ),
                        onPressed: isFetching ? null : _clearFields,
                        child: const Text('Clear'),
                      ),
                      TextButton(
                        onPressed: isFetching ? null : _generateMockData,
                        child: const Text('Generate'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent.shade700,
                        ),
                        onPressed: isFetching ? null : _deleteMockData,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
