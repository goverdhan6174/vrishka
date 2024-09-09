import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/pages/rsal/detail/rsal_detail_page.dart';
import 'package:vriksha/pages/rsal/list/search_rsal.dart';

class RsalsList extends StatefulWidget {
  const RsalsList({super.key});

  @override
  State<RsalsList> createState() => _RsalsListState();
}

class _RsalsListState extends State<RsalsList> {
  List<Rsal> _filteredRsals = [];
  bool _showFilterRsals = false;

  void _updateFilteredRsal(List<Rsal> rsals) {
    setState(() {
      _filteredRsals = rsals;
      _showFilterRsals = true;
    });
  }

  void _clearFilteredRsal() {
    setState(() {
      _filteredRsals = [];
      _showFilterRsals = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchRsalPage(
          updateRsals: _updateFilteredRsal,
          clearRsals: _clearFilteredRsal,
        ),
        FutureBuilder<List<Rsal>>(
          future: DB.getRsals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No rsals found.'));
            }

            final rsals = snapshot.data!;
            final filteredRsal = _showFilterRsals ? _filteredRsals : rsals;
            return Expanded(
              child: ListView.builder(
                itemCount: filteredRsal.length,
                itemBuilder: (context, index) {
                  final rsal = filteredRsal[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      child: ListTile(
                        title: Text(rsal.name),
                        subtitle: Text('Status: ${rsal.status}'),
                        iconColor: rsal.status.toUpperCase() == "COMPLETED"
                            ? Colors.amber
                            : Colors.green,
                        leading: const Icon(Icons.circle),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RsalDetailPage(rsalId: rsal.id),
                            ),
                          );
                        },
                        trailing: Text(
                          'Created On\n${DateFormat('dd/MM/yyyy').format((rsal.createDate))}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
