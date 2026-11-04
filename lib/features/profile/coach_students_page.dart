import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
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
        .order('display_name', ascending: true)
        .timeout(const Duration(seconds: 8));

    final students = response
        .map((e) => {
              'id': e['id'],
              'name': e['display_name'] ?? '',
            })
        .toList();

    if (students.isEmpty) {
      return students;
    }

    final studentIds = students.map((e) => e['id'].toString()).toList();

    const fields = [
      'caloriesTracked',
      'calorieGoal',
      'proteinTracked',
      'fatTracked',
      'carbsTracked',
    ];
    final rows = await supabase
        .from('tracked_days')
        .select('user_id, ${fields.join(', ')}')
        .eq('day', todayKey)
        .inFilter('user_id', studentIds)
        .timeout(const Duration(seconds: 8));

    final lastEntries = await Future.wait(studentIds.map((id) => supabase
        .from('tracked_days')
        .select('day')
        .eq('user_id', id)
        .gt('caloriesTracked', 0)
        .lte('day', todayKey)
        .order('day', ascending: false)
        .limit(1)
        .maybeSingle()
        .timeout(const Duration(seconds: 8))));
    final lastByUser = {
      for (var i = 0; i < studentIds.length; i++)
        studentIds[i]: lastEntries[i]?['day'],
    };

    final byUser = {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['user_id'].toString(): {
          for (final f in fields) f: (row[f] as num?)?.toDouble(),
        },
    };

    return students
        .map((student) => {
              ...student,
              'today': byUser[student['id'].toString()],
              'last_day': lastByUser[student['id'].toString()],
            })
        .toList();
  }

  Future<void> _refresh() async {
    final future = _fetchStudents();
    setState(() {
      _studentsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: MainAppbar(title: s.myStudentsTitle, iconData: Icons.groups),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CenteredMessage(
              icon: Icons.cloud_off_outlined,
              text: s.studentLoadError,
              onRefresh: _refresh,
            );
          }

          final students = List<Map<String, dynamic>>.of(snapshot.data ?? []);
          if (students.isEmpty) {
            return _CenteredMessage(
              icon: Icons.group_outlined,
              text: s.noStudents,
              onRefresh: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: students.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StudentsSummary(
                    students: students,
                  );
                }
                final student = students[index - 1];
                final studentId = student['id'].toString();
                final rawName = student['name'].toString().trim();
                final studentName =
                    rawName.isEmpty ? s.unnamedStudentLabel : rawName;
                return _StudentCard(
                  name: studentName,
                  student: student,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentMacrosPage(
                          studentId: studentId,
                          studentName: studentName,
                        ),
                      ),
                    );
                    if (mounted) await _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StudentsSummary extends StatelessWidget {
  final List<Map<String, dynamic>> students;

  const _StudentsSummary({required this.students});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final logged = students.where((st) {
      final today = st['today'] as Map<String, double?>?;
      return (today?['caloriesTracked'] ?? 0) > 0;
    }).length;

    final total = students.length;
    final ratio = total == 0 ? 0.0 : logged / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).coachTodayTitle} ⚡',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          AtlasBrandPanel(
            padding: const EdgeInsets.all(18),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$logged/$total',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(S.of(context).coachLoggedToday,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.74),
                              fontWeight: FontWeight.w600)),
                    ),
                    Text('${(ratio * 100).round()} %',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic> student;
  final VoidCallback onTap;

  const _StudentCard(
      {required this.name, required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = S.of(context);
    final today = student['today'] as Map<String, double?>?;
    double v(String key) => today?[key] ?? 0;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // MacroEnergyBar carries its own vertical padding.
          padding: EdgeInsets.fromLTRB(18, 16, 18, today == null ? 16 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: atlasBrandGradientColors,
                      ),
                    ),
                    child: Text(
                        name.trim().isEmpty
                            ? '?'
                            : name.trim()[0].toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                        today == null
                            ? s.noDataToday
                            : '${formatNumber(v('caloriesTracked'))} / ${formatNumber(v('calorieGoal'))} ${s.kcalLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  s.lastJournalDay(student['last_day'] == null
                      ? '—'
                      : DateFormat.yMMMd(
                              Localizations.localeOf(context).toString())
                          .format(
                              DateTime.parse(student['last_day'].toString()))),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              if (today != null)
                // No legend popup here: a tap opens the student.
                IgnorePointer(
                  child: MacroEnergyBar(
                    calories: v('caloriesTracked'),
                    goal: v('calorieGoal'),
                    carbs: v('carbsTracked'),
                    fats: v('fatTracked'),
                    proteins: v('proteinTracked'),
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function() onRefresh;

  const _CenteredMessage(
      {required this.icon, required this.text, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // ListView so pull-to-refresh also works on empty/error states.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(icon, size: 56, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
