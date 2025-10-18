import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'student_macros_page.dart';

class CoachStudentsPage extends StatefulWidget {
  const CoachStudentsPage({super.key});

  @override
  State<CoachStudentsPage> createState() => _CoachStudentsPageState();
}

class _CoachStudentsPageState extends State<CoachStudentsPage> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudents();
  }

  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    final supabase = locator<SupabaseClient>();
    final coachId = supabase.auth.currentUser?.id;
    if (coachId == null) return [];

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final todayKey = DateFormat('yyyy-MM-dd').format(todayOnly);

    final List<Map<String, dynamic>> response = await supabase
        .from('users')
        .select('id, display_name')
        .eq('coach_id', coachId)
        .order('display_name', ascending: true);

    final students = response
        .map((e) => {
              'id': e['id'],
              'name': e['display_name'] ?? e['id'],
            })
        .toList();

    if (students.isEmpty) {
      return students;
    }

    final studentIds = students.map((e) => e['id'].toString()).toList();

    final macroRows = await supabase
        .from('tracked_days')
        .select(
          '''
          user_id,
          proteinTracked,
          proteinGoal,
          fatTracked,
          fatGoal,
          carbsTracked,
          carbsGoal
          ''',
        )
        .eq('day', todayKey)
        .inFilter('user_id', studentIds);

    final macrosByUser =
        <String, ({double? proteinTracked, double? proteinGoal, double? fatTracked, double? fatGoal, double? carbsTracked, double? carbsGoal})>{};

    for (final row in macroRows.cast<Map<String, dynamic>>()) {
      final userId = row['user_id']?.toString();
      if (userId == null) continue;

      macrosByUser[userId] = (
        proteinTracked: (row['proteinTracked'] as num?)?.toDouble(),
        proteinGoal: (row['proteinGoal'] as num?)?.toDouble(),
        fatTracked: (row['fatTracked'] as num?)?.toDouble(),
        fatGoal: (row['fatGoal'] as num?)?.toDouble(),
        carbsTracked: (row['carbsTracked'] as num?)?.toDouble(),
        carbsGoal: (row['carbsGoal'] as num?)?.toDouble(),
      );
    }

    return students
        .map((student) {
          final entry = macrosByUser[student['id'].toString()];
          return {
            ...student,
            'proteinTracked': entry?.proteinTracked,
            'proteinGoal': entry?.proteinGoal,
            'fatTracked': entry?.fatTracked,
            'fatGoal': entry?.fatGoal,
            'carbsTracked': entry?.carbsTracked,
            'carbsGoal': entry?.carbsGoal,
          };
        })
        .toList();
  }

  String _formatMacroValue(double? tracked, double? goal) {
    final trackedStr = _formatNumber(tracked);
    final goalStr = _formatNumber(goal);
    return '$trackedStr / $goalStr g';
  }

  String _formatNumber(double? value) {
    if (value == null) return '-';
    if ((value % 1).abs() < 0.01) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).myStudentsTitle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(
                  child:
                      Text('${S.of(context).errorPrefix} ${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!;
          if (students.isEmpty) {
            return Center(child: Text(S.of(context).noStudents));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final studentId = student['id'].toString();
              final studentName = student['name'].toString();
              final double? proteinTracked =
                  student['proteinTracked'] as double?;
              final double? proteinGoal = student['proteinGoal'] as double?;
              final double? fatTracked = student['fatTracked'] as double?;
              final double? fatGoal = student['fatGoal'] as double?;
              final double? carbsTracked = student['carbsTracked'] as double?;
              final double? carbsGoal = student['carbsGoal'] as double?;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentMacrosPage(
                          studentId: studentId,
                          studentName: studentName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.person,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      title: Text(
                        studentName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Builder(
                        builder: (context) {
                          final macrosTexts = [
                            (
                              S.of(context).proteinLabel,
                              _formatMacroValue(proteinTracked, proteinGoal),
                            ),
                            (
                              S.of(context).fatLabel,
                              _formatMacroValue(fatTracked, fatGoal),
                            ),
                            (
                              S.of(context).carbsLabel,
                              _formatMacroValue(carbsTracked, carbsGoal),
                            ),
                          ];

                          final hasData = [
                            proteinTracked,
                            proteinGoal,
                            fatTracked,
                            fatGoal,
                            carbsTracked,
                            carbsGoal,
                          ].any((value) => value != null);

                          if (!hasData) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                S.of(context).noDataToday,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }

                          final textStyle =
                              Theme.of(context).textTheme.bodySmall;

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: macrosTexts
                                  .map(
                                    (entry) => Text(
                                      '${entry.$1}: ${entry.$2}',
                                      style: textStyle,
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
