import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vriksha/components/cards/month_info_card.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/helpers/current_format.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:vriksha/pages/rsal/create/create_rsal_page.dart';

class RsalDetailPage extends StatefulWidget {
  final String rsalId;

  const RsalDetailPage({super.key, required this.rsalId});

  @override
  State<RsalDetailPage> createState() => _RsalDetailPageState();
}

class _RsalDetailPageState extends State<RsalDetailPage> {
  bool _applyFilter = false;

  @override
  Widget build(BuildContext context) {
    var cardWidth = MediaQuery.of(context).size.width * 0.9;
    return FutureBuilder(
        future: DB.getRsal(widget.rsalId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No rsal found.'));
          }

          Rsal rsal = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(rsal.name),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount: ${indianRupeeFormat(rsal.principalAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Duration: ${rsal.duration}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Created On: ${DateFormat('dd/MM/yyyy').format(rsal.createDate)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Status: ${rsal.status}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: rsal.status.toUpperCase() == "COMPLETED"
                                    ? Colors.amber
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      rsal.status.toUpperCase() == "STALE"
                          ? IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateRsalPage(rsalId: rsal.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.group_add_rounded))
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  _applyFilter = !_applyFilter;
                                });
                              },
                              icon: Icon(
                                _applyFilter
                                    ? Icons.filter_alt
                                    : Icons.filter_alt_off,
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: rsal.status == "RUNNING" ? rsal.duration : 0,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: cardWidth > 350 ? 350 : cardWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: MonthInfoCard(
                            rsalId: rsal.id,
                            month: index + 1,
                            showFilteredMembers: _applyFilter,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }
}
