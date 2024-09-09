library VrikshaDB;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vriksha/models/member.dart';
import 'package:vriksha/models/member_rsal_info.dart';
import 'package:vriksha/models/rsal_emi.dart';
import 'package:vriksha/models/rsal_monthly_info.dart';
import 'package:vriksha/models/rsal.dart';
import 'package:vriksha/models/rsal_payment.dart';
import 'package:vriksha/helpers/generate_month_emi.dart';

part './db_example_generator.dart';

class DB {
  DB._privateConstructor();
  static final DB instance = DB._privateConstructor();
  static Database? _database;

  static const _databaseName = "vriksha_database.db";
  static const _membersTableName = "vriksha_members";
  static const _rsalsTableName = 'vriksha_rsals';
  static const _rsalMemberTableName = "vriksha_rsal_members";
  static const _rsalMonthlyEMITableName = "vriksha_emi";
  static const _rsalPaymentTableName = "vriksha_payment";
  static const _databaseVersion = 1;

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await init();
    return _database!;
  }

  static Future<Database> init() async {
    // sqfliteFfiInit();
    // databaseFactory = databaseFactoryFfi;
    final path = join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS $_rsalsTableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            principal_amount INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL
          )
        ''');

    await db.execute('''
          CREATE TABLE if not EXISTS $_membersTableName (
            id TEXT PRIMARY key,
            name TEXT NOT NULL,
            mobile TEXT NOT NULL
          )
        ''');

    await db.execute('''
          CREATE TABLE if not EXISTS $_rsalMemberTableName (
            rsal_id TEXT NOT NULL,
            member_id TEXT NOT NULL,
            FOREIGN KEY(rsal_id) REFERENCES $_rsalsTableName(id),
            FOREIGN KEY(member_id) REFERENCES $_membersTableName(id),
            primary KEY (rsal_id, member_id)
          )
        ''');

    await db.execute('''
          CREATE TABLE If NOT EXISTS $_rsalMonthlyEMITableName (
            rsal_id TEXT NOT NULL,
            member_id TEXT,
            month INTEGER NOT NULL,
            percentage NUMERIC not NULL,
            emi NUMERIC NOT NULL,
            FOREIGN KEY(rsal_id) REFERENCES $_rsalsTableName(id),
            FOREIGN KEY(member_id) REFERENCES $_membersTableName(id),
            PRIMARY key (rsal_id, month)
          )
        ''');

    await db.execute('''
          CREATE TABLE If NOT EXISTS $_rsalPaymentTableName (
            rsal_id TEXT NOT NULL,
            member_id TEXT NOT NULL,
            month INTEGER NOT NULL,
            paid_amount NUMERIC not NULL,
            FOREIGN KEY(rsal_id) REFERENCES $_rsalsTableName(id),
            FOREIGN KEY(member_id) REFERENCES $_membersTableName(id),
            PRIMARY key (rsal_id, member_id, month)
          )
        ''');
  }

  static Future close() async => _database!.close();

  static Future<void> generateMockData() async {
    Database db = await instance.database;

    final list = <(double, String)>[
      (200000, "RUNNING"),
      (900000, "COMPLETED"),
      (900000, "RUNNING"),
      (900000, "RUNNING"),
      (500000, "COMPLETED"),
      (100000, "RUNNING"),
      (900000, "RUNNING"),
      (200000, "COMPLETED"),
      (900000, "RUNNING"),
      (900000, "RUNNING"),
      (300000, "STALE"),
      (900000, "RUNNING"),
      (200000, "RUNNING")
    ];

    List<String> mockMemberList = [];
    final mockMembersMap = await db.query(
      _membersTableName,
      where: 'id LIKE ?',
      whereArgs: ['mock_member%'],
    );
    if (mockMembersMap.isEmpty) {
      final memQueryNList = generateMember(_membersTableName);
      db.execute(memQueryNList.$1);
      mockMemberList = memQueryNList.$2;
    } else {
      for (var map in mockMembersMap) {
        mockMemberList.add(((map['id'] ?? "") as String));
      }
    }
    for (var element in list) {
      final rsal = generateRSAL(element.$1, element.$2, mockMemberList);
      final queries = rsal.getRawQueriesList(
        _rsalsTableName,
        _rsalMemberTableName,
        _rsalMonthlyEMITableName,
        _rsalPaymentTableName,
      );

      await db.transaction((txn) async {
        final qLength = queries.length;
        if (qLength > 0) await txn.execute(queries[0]); // RSAL
        if (qLength > 1) await txn.execute(queries[1]); // MAP MEMBER TO RSAL
        if (qLength > 2) await txn.execute(queries[2]); // MONTH EMI INFO
        if (qLength > 3) await txn.execute(queries[3]); // MEMBER PAYMENT
        debugPrint(
            'All ${rsal.rsalName} queries executed successfully within transaction.');
      });
    }
    return;
  }

  static Future<void> deleteMockData() async {
    Database db = await instance.database;
    await db.delete(
      _rsalPaymentTableName,
      where: 'rsal_id LIKE ? OR member_id LIKE ?',
      whereArgs: ['mock_rsal%', 'mock_member%'],
    );
    await db.delete(
      _rsalMonthlyEMITableName,
      where: 'rsal_id LIKE ? OR member_id LIKE ?',
      whereArgs: ['mock_rsal%', 'mock_member%'],
    );
    await db.delete(
      _rsalMemberTableName,
      where: 'rsal_id LIKE ? OR member_id LIKE ?',
      whereArgs: ['mock_rsal%', 'mock_member%'],
    );
    await db.delete(
      _rsalsTableName,
      where: 'id LIKE ?',
      whereArgs: ['mock_rsal%'],
    );
    await db.delete(
      _membersTableName,
      where: 'id LIKE ?',
      whereArgs: ['mock_member%'],
    );
  }

  static Future<Member?> getMember(String id) async {
    Database db = await instance.database;
    final maps = await db.query(_membersTableName,
        where: "id = ?", whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Member.fromMap(maps.first);
  }

  static Future<int> insertMember(Member member) async {
    Database db = await instance.database;
    final id = await db.insert(_membersTableName, member.toMapWithoutRsalIds());
    for (final rsalId in member.rsalIds) {
      await db.insert(_rsalMemberTableName, {'rsalId': rsalId, 'memberId': id});
    }
    return id;
  }

  static Future<List<String>> getRsalIdsForMember(String memberId) async {
    Database db = await instance.database;
    final maps = await db.query(_rsalMemberTableName,
        where: "member_id = ?", whereArgs: [memberId]);
    return maps.map((map) => map['rsal_id'] as String).toList();
  }

  static Future<List<Member>> getMembers() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(_membersTableName);

    final mapsWithRsalIds = <Map<String, dynamic>>[];
    for (var map in maps) {
      final rsalIds = await getRsalIdsForMember(map['id']);
      mapsWithRsalIds.add({...map, 'rsalIds': rsalIds});
    }

    final membersList = List.generate(
      mapsWithRsalIds.length,
      (index) => Member.fromMap(mapsWithRsalIds[index]),
    );

    return membersList;
  }

  static Future<int> updateMember(int id, Member member) async {
    Database db = await instance.database;
    final data = {'name': member.name, 'mobile': member.mobile};
    return db.update(_membersTableName, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteMember(String id) async {
    Database db = await instance.database;
    try {
      return await db
          .delete(_membersTableName, where: 'id = ?', whereArgs: [id]);
    } catch (err) {
      debugPrint('Error delete data');
      return 0;
    }
  }

  static Future<int> insertRsal(Rsal rsal) async {
    Database db = await instance.database;
    final id = await db.insert(_rsalsTableName, rsal.toMapWithoutMemberIds());

    for (final memberId in rsal.memberIds) {
      await db.insert(
          _rsalMemberTableName, {'rsalId': rsal.id, 'memberId': memberId});
    }

    return id;
  }

  static Future<List<String>> _getMemberIdsForRsal(String rsalId) async {
    Database db = await instance.database;
    final maps = await db
        .query(_rsalMemberTableName, where: "rsal_id = ?", whereArgs: [rsalId]);
    return maps.map((map) => map['member_id'] as String).toList();
  }

  static Future<List<Member>> getRsalMembers(String rsalId) async {
    Database db = await instance.database;
    final rsalMembersMap = await db
        .query(_rsalMemberTableName, where: "rsal_id = ?", whereArgs: [rsalId]);
    if (rsalMembersMap.isEmpty) return List.empty();
    final memberIds =
        rsalMembersMap.toList().map((e) => e['member_id']).toList();
    final membersMap = await db.query(_membersTableName,
        where: "id IN (${memberIds.map((_) => '?').join(', ')})",
        whereArgs: memberIds);
    return List.generate(
      membersMap.length,
      (index) => Member.fromMap(membersMap[index]),
    );
  }

  static Future<Rsal?> getRsal(String id) async {
    Database db = await instance.database;
    final maps = await db.query(_rsalsTableName,
        where: "id = ?", whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;

    final memberIds = await _getMemberIdsForRsal(id);
    return Rsal.fromMap({...maps.first, "memberIds": memberIds});
  }

  static Future<List<Rsal>> getRsals() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(_rsalsTableName);
    if (maps.isEmpty) return [];

    final mapsWithMemberIds = <Map<String, dynamic>>[];
    for (var map in maps) {
      final memberIds = await _getMemberIdsForRsal(map['id']);
      mapsWithMemberIds.add({...map, 'memberIds': memberIds});
    }

    final rsalList = List.generate(
      mapsWithMemberIds.length,
      (index) => Rsal.fromMap(mapsWithMemberIds[index]),
    );

    return rsalList;
  }

  static Future<List<RsalMonthlyInfo>> getAllMonthInfo(Rsal rsal) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> monthlyInfo = [];
    for (var month = 1; month <= rsal.duration; month++) {
      final emiInfo = await db.query(
        _rsalMonthlyEMITableName,
        where: "rsal_id = ? AND month = ?",
        whereArgs: [rsal.id, month],
        limit: 1,
      );
      if (emiInfo.isNotEmpty) {
        final paymentInfo = await db.query(
          _rsalPaymentTableName,
          where: "rsal_id = ? AND month = ?",
          whereArgs: [rsal.id, month],
        );
        monthlyInfo.add({...emiInfo.first, "payments": paymentInfo});
      }
    }
    return List.generate(
      monthlyInfo.length,
      (index) => RsalMonthlyInfo.fromMap(monthlyInfo[index]),
    );
  }

  static Future<MemberRsalInfo> getMemberRsalInfo(
      String rsalId, String memberId) async {
    final now = DateTime.now();
    final emptyRsal = Rsal(name: "", createDate: now, principalAmount: 0);
    Database db = await instance.database;
    final maps = await db.query(_rsalsTableName,
        where: "id = ?", whereArgs: [rsalId], limit: 1);
    if (maps.isEmpty) {
      return MemberRsalInfo(rsal: emptyRsal);
    }
    final rsal = Rsal.fromMap(maps.first);
    final List<Map<String, dynamic>> memberPayments = [];
    for (var month = 1; month <= rsal.duration; month++) {
      final emiInfo = await db.query(
        _rsalMonthlyEMITableName,
        where: "rsal_id = ? AND month = ?",
        whereArgs: [rsalId, month],
        limit: 1,
      );
      if (emiInfo.isNotEmpty) {
        final paymentInfo = await db.query(
          _rsalPaymentTableName,
          where: "rsal_id = ? AND member_id = ? AND month = ?",
          whereArgs: [rsalId, memberId, month],
        );
        memberPayments.add({...paymentInfo.first, ...emiInfo.first});
      }
    }
    return MemberRsalInfo.fromMap(
      {"rsal": maps.first, "memberPayments": memberPayments},
    );
  }

  static Future<RsalEmi?> getRsalMonthInfo(String rsalId, int month) async {
    Database db = await instance.database;
    final emiInfo = await db.query(
      _rsalMonthlyEMITableName,
      where: "rsal_id = ? AND month = ?",
      whereArgs: [rsalId, month],
      limit: 1,
    );
    if (emiInfo.isEmpty) return null;
    return RsalEmi.fromMap(emiInfo.first);
  }

  static Future<RsalMonthlyInfo> getRsalMonthAndPaymentInfo(
      String rsalId, int month) async {
    Database db = await instance.database;
    final emiInfo = await db.query(
      _rsalMonthlyEMITableName,
      where: "rsal_id = ? AND month = ?",
      whereArgs: [rsalId, month],
      limit: 1,
    );
    if (emiInfo.isEmpty) return RsalMonthlyInfo(rsalId: rsalId, month: month);
    final paymentInfo = await db.query(
      _rsalPaymentTableName,
      where: "rsal_id = ? AND month = ?",
      whereArgs: [rsalId, month],
    );
    return RsalMonthlyInfo.fromMap({...emiInfo.first, "payments": paymentInfo});
  }

  static Future<RsalPayment?> getRsalPayment(
      String rsalId, String memberId, int month) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      _rsalPaymentTableName,
      where: 'rsal_id = ? AND member_id = ? AND month = ?',
      whereArgs: [rsalId, memberId, month],
    );
    if (maps.isNotEmpty) {
      return RsalPayment.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> queryRow(name) async {
    Database db = await instance.database;
    return await db.query(_membersTableName, where: "name LIKE '%$name%' ");
  }

  static Future<int> updateRsalMonthlyEMI(
      String rsalId, int month, double percentage, double emi) async {
    Database db = await instance.database;
    final data = {
      'percentage': percentage,
      'emi': emi,
    };
    return await db.update(
      _rsalMonthlyEMITableName,
      data,
      where: 'rsal_id = ? AND month = ?',
      whereArgs: [rsalId, month],
    );
  }

  static Future<int> createMember(Member member) async {
    Database db = await instance.database;
    return await db.insert(_membersTableName, member.toMapWithoutRsalIds());
  }

  static Future<int> createRsal(Rsal rsal) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    batch.insert(_rsalsTableName, rsal.toMapWithoutMemberIds());
    for (final memberId in rsal.memberIds) {
      batch.insert(
          _rsalMemberTableName, {'rsal_id': rsal.id, 'member_id': memberId});
    }
    await batch.commit(noResult: true);
    return 1;
  }

  static Future<int> updateRsal(Rsal rsal) async {
    Database db = await instance.database;
    // Update the RSAL in the rsals table
    int result = await db.update(
      _rsalsTableName,
      rsal.toMapWithoutMemberIds(),
      where: 'id = ?',
      whereArgs: [rsal.id],
    );
    // Delete existing members associated with the RSAL
    await db.delete(
      _rsalMemberTableName,
      where: 'rsal_id = ?',
      whereArgs: [rsal.id],
    );
    // Add the updated members to the rsal_members table
    Batch batch = db.batch();
    for (final memberId in rsal.memberIds) {
      batch.insert(
        _rsalMemberTableName,
        {'rsal_id': rsal.id, 'member_id': memberId},
      );
    }
    await batch.commit(noResult: true);
    return result;
  }

  static Future<void> addMembersToRsal(
      String rsalId, List<String> memberIds) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (final memberId in memberIds) {
      batch.insert(
          _rsalMemberTableName, {'rsal_id': rsalId, 'member_id': memberId});
    }
    await batch.commit(noResult: true);
  }

  static Future<void> addMemberToRsal(String rsalId, String memberId) async {
    Database db = await instance.database;
    await db.insert(
        _rsalMemberTableName, {'rsal_id': rsalId, 'member_id': memberId});
  }

  static Future<void> deleteMembersFromRsal(String rsalId) async {
    Database db = await instance.database;
    await db.delete(
      _rsalMemberTableName,
      where: 'rsal_id = ?',
      whereArgs: [rsalId],
    );
  }

  static Future<int> updateRsalStatus(String rsalId, String status) async {
    Database db = await instance.database;
    return await db.update(
      _rsalsTableName,
      {'status': status},
      where: 'id = ?',
      whereArgs: [rsalId],
    );
  }

  static Future<void> createOrUpdateRsalPayment(RsalPayment rsalPayment) async {
    Database db = await instance.database;

    // Check if the payment record exists
    final List<Map<String, dynamic>> existingRecords = await db.query(
      _rsalPaymentTableName,
      where: 'rsal_id = ? AND member_id = ? AND month = ?',
      whereArgs: [rsalPayment.rsalId, rsalPayment.memberId, rsalPayment.month],
    );

    // If the record exists, update it
    if (existingRecords.isNotEmpty) {
      final alreadyPaidAmount = existingRecords.first['paid_amount'] ?? 0;
      await db.update(
        _rsalPaymentTableName,
        {'paid_amount': rsalPayment.paidAmount + alreadyPaidAmount},
        where: 'rsal_id = ? AND member_id = ? AND month = ?',
        whereArgs: [
          rsalPayment.rsalId,
          rsalPayment.memberId,
          rsalPayment.month
        ],
      );
    } else {
      // Otherwise, create a new record
      await db.insert(_rsalPaymentTableName, rsalPayment.toMap());
    }
  }

  // Future<void> insertOrUpdateRsalPayment(RsalPayment rsalPayment) async {
  //   Database db = await instance.database;
  //   await db.insert(_rsalPaymentTableName, rsalPayment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  // }

  static Future<void> insertRsalEmi(RsalEmi rsalEmi) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      // Check if RSAL exists
      final rsalExists = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM $_rsalsTableName WHERE id = ?',
          [rsalEmi.rsalId]))!;

      // Check if the rsal-month key is already present
      final emiExists = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM $_rsalMonthlyEMITableName WHERE rsal_id = ? AND month = ?',
          [rsalEmi.rsalId, rsalEmi.month]))!;

      if (rsalExists > 0 && emiExists == 0) {
        await txn.insert(_rsalMonthlyEMITableName, rsalEmi.toMap());
      } else {
        // Handle the case when RSAL doesn't exist or rsal-month key is present
        throw Exception(
            'RSAL not found or EMI for the given month already exists.');
      }
    });
  }

  static Future<List<Rsal>> searchRsals(
      String? name, DateTime? createdDate, DateTime? endDate) async {
    Database db = await instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (name != null) {
      whereClauses.add('name LIKE ?');
      whereArgs.add('%$name%');
    }

    if (createdDate != null) {
      whereClauses.add('strftime("%m-%d", created_at) = ?');
      whereArgs.add(DateFormat('MM-dd').format(createdDate));
    }

    if (endDate != null) {
      whereClauses.add(
          'strftime("%m-%d", datetime(created_at, "+" || duration || " months")) = ?');
      whereArgs.add(DateFormat('MM-dd').format(endDate));
    }

    String whereString =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '1';

    final List<Map<String, dynamic>> maps = await db.query(
      _rsalsTableName,
      where: whereString,
      whereArgs: whereArgs,
    );

    return List.generate(maps.length, (i) {
      return Rsal.fromMap(maps[i]);
    });
  }
}
