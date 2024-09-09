import 'package:flutter/material.dart';
import 'package:vriksha/models/member.dart';
import 'package:vriksha/db/instance.dart';
import 'package:vriksha/pages/member/detail/member_detail_page.dart';

class MembersList extends StatefulWidget {
  const MembersList({super.key});

  @override
  State<MembersList> createState() => _MembersListState();
}

class _MembersListState extends State<MembersList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Member>>(
      future: DB.getMembers(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final members = snapshot.data!;
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: Card(
                  child: ListTile(
                    title: Text(member.name),
                    subtitle: Text('Mobile: ${member.mobile}'),
                    leading: const Icon(Icons.person),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemberDetailPage(member: member),
                        ),
                      );
                    },
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
    );
  }
}
