import 'package:flutter/material.dart';
import 'package:vriksha/components/cards/member_rsal_card.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/models/member.dart';

class MemberDetailPage extends StatefulWidget {
  final Member member;

  const MemberDetailPage({super.key, required this.member});

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  bool _applyFilter = false;

  @override
  Widget build(BuildContext context) {
    var cardWidth = MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
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
                        'Name: ${widget.member.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Mobile: ${widget.member.mobile}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _applyFilter = !_applyFilter;
                    });
                  },
                  icon: Icon(
                    _applyFilter ? Icons.filter_alt : Icons.filter_alt_off,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: DB.getRsalIdsForMember(widget.member.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final rsalIds = snapshot.data!;
                  return ListView.builder(
                    itemCount: rsalIds.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: cardWidth > 350 ? 350 : cardWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: MemberRsalCard(
                            rsalId: rsalIds[index],
                            memberId: widget.member.id,
                            showFilteredMembers: _applyFilter,
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
