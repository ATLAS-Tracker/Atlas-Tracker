import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_tab_bar.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging/logging.dart';
import 'coach_macro_goal_remote.dart';

class SetStudentMacrosPage extends StatefulWidget {
  final String studentId;
  final int initialCarbs;
  final int initialFat;
  final int initialProtein;
  const SetStudentMacrosPage({
    super.key,
    required this.studentId,
    required this.initialCarbs,
    required this.initialFat,
    required this.initialProtein,
  });

  @override
  State<SetStudentMacrosPage> createState() => _SetStudentMacrosPageState();
}

class _SetStudentMacrosPageState extends State<SetStudentMacrosPage> {
  // Toujours stocker des dates "pures" (00:00)
  DateTime _startDate = _today();
  bool _loadingLatest = true;
  int _tab = 0;
  bool _saving = false;
  int? _previousCalories;
  List<Map<String, dynamic>> _goalHistory = [];

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Utilitaire pour normaliser toute date reçue
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  final log = Logger('SetStudentMacrosPage');
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _proteinController;

  int _calculatedCalories = 0;

  @override
  void initState() {
    super.initState();
    _startDate = _dateOnly(_startDate);
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _proteinController = TextEditingController();

    _carbsController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);
    _proteinController.addListener(_calculateCalories);

    // Récupère le dernier objectif depuis Supabase pour pré-remplir
    // les champs avec les dernières valeurs enregistrées pour l'élève.
    _loadLatestGoal();
  }

  @override
  void dispose() {
    _carbsController.dispose();
    _fatController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  void _calculateCalories() {
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fat = int.tryParse(_fatController.text) ?? 0;
    final protein = int.tryParse(_proteinController.text) ?? 0;

    setState(() {
      _calculatedCalories = (carbs * 4) + (fat * 9) + (protein * 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.setMacrosLabel)),
      body: SafeArea(
        child: _loadingLatest
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: AtlasTabBar(
                          labels: [s.macroGoalsTabLabel, s.historyLabel],
                          selectedIndex: _tab,
                          onSelected: (i) => setState(() => _tab = i),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _tab == 0 ? _goalsTab() : _historyTab()),
                ],
              ),
      ),
    );
  }

  Widget _goalsTab() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 28),
                    _sectionTitle(
                        Icons.donut_large_rounded, s.macroDistributionTitle),
                    _macroField(
                        _carbsController, s.carbsLabel, MacroVisuals.carbs, 4),
                    const SizedBox(height: 10),
                    _macroField(
                        _fatController, s.fatLabel, MacroVisuals.fats, 9),
                    const SizedBox(height: 10),
                    _macroField(_proteinController, s.proteinLabel,
                        MacroVisuals.proteins, 4),
                    const SizedBox(height: 28),
                    _bodyGoalPlaceholder(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Date + bouton toujours visibles : on voit en permanence
        // à partir de quand les nouveaux objectifs s'appliquent.
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dateStepper(locale),
                    if (!_allFieldsFilled)
                      Text(s.enterValidMacrosHelp,
                          style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed:
                          _saving || !_allFieldsFilled ? null : _saveMacros,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.check_rounded),
                      label: Text(s.buttonSaveLabel),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        textStyle: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyTab() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_goalHistory.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              for (final row in _goalHistory) ...[
                _previousGoalCard(
                    Localizations.localeOf(context).toString(), row),
                const SizedBox(height: 12),
              ],
            ]),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded,
                size: 36, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(S.of(context).macroGoalHistoryEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ]),
      ),
    );
  }

  bool get _allFieldsFilled =>
      [_carbsController, _fatController, _proteinController].every((c) {
        final grams = int.tryParse(c.text);
        return grams != null && grams >= 0 && grams <= 1000;
      }) &&
      _calculatedCalories > 0 &&
      _calculatedCalories <= 10000;

  // ponytail: aperçu désactivé, à brancher quand l'objectif physique
  // (prise de masse / sèche / maintien + poids cible) sera stocké pour l'élève.
  Widget _bodyGoalPlaceholder() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          Icons.flag_rounded,
          s.goalLabel,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(s.comingSoonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.bodyGoalPreviewDescription,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (icon, label) in [
                  (Icons.trending_down_rounded, s.goalLoseWeightDashboard),
                  (
                    Icons.horizontal_rule_rounded,
                    s.goalMaintainWeightDashboard
                  ),
                  (Icons.trending_up_rounded, s.goalGainWeightDashboard),
                ])
                  ChoiceChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selected: false,
                    onSelected: null,
                  ),
              ]),
              const SizedBox(height: 14),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: s.targetWeightLabel,
                  hintText: '—',
                  suffixText: s.kgLabel,
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final theme = Theme.of(context);
    final s = S.of(context);
    const onBrand = Colors.white;
    return AtlasBrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.dailyMacroGoalsTitle.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: onBrand.withValues(alpha: 0.8),
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$_calculatedCalories',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: onBrand,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  )),
              TextSpan(
                  text: ' ${s.kcalLabel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onBrand.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
          if (_previousCalories != null &&
              _previousCalories != _calculatedCalories) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: onBrand.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                s.trendVsGoal(
                    '${_calculatedCalories > _previousCalories! ? '+' : ''}'
                    '${_calculatedCalories - _previousCalories!} ${s.kcalLabel}'),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: onBrand, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 16),
          MacroEnergyBar(
            calories: _calculatedCalories.toDouble(),
            goal: _calculatedCalories.toDouble(),
            carbs: double.tryParse(_carbsController.text) ?? 0,
            fats: double.tryParse(_fatController.text) ?? 0,
            proteins: double.tryParse(_proteinController.text) ?? 0,
            backgroundColor: onBrand.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Text(s.macroCaloriesExplanation,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: onBrand.withValues(alpha: 0.75))),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {Widget? trailing}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(children: [
        // Même badge que les cartes de la page élève.
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: colors.primary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(child: trailing),
        ],
      ]),
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? padding}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: atlasCardDecoration(colors),
      child: child,
    );
  }

  Widget _dateStepper(String locale) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
          onPressed: _startDate.isAfter(_today()) ? _goToPreviousDay : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: _selectDate,
            icon: Icon(Icons.event_rounded, size: 20, color: colors.primary),
            label: Text(
              DateFormat.yMMMMd(locale).format(_startDate),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          onPressed: _goToNextDay,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _previousGoalCard(String locale, Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = S.of(context);
    final carbs = (row['carb_goal'] as num).toInt();
    final fat = (row['fat_goal'] as num).toInt();
    final protein = (row['protein_goal'] as num).toInt();
    final calories = carbs * 4 + fat * 9 + protein * 4;
    Widget chip(String label, int? grams, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$label · ${grams ?? '-'} g',
                style: theme.textTheme.labelMedium),
          ]),
        );
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.history_rounded,
                size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.previousGoalAppliedOn(DateFormat.yMMMd(locale)
                    .format(DateTime.parse(row['start_date']))),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            Text('$calories ${s.kcalLabel}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip(s.carbsLabel, carbs, carbColor),
            chip(s.fatLabel, fat, fatColor),
            chip(s.proteinLabel, protein, proteinColor),
          ]),
        ],
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label,
      MacroVisual visual, int caloriesPerGram) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final energy = (int.tryParse(controller.text) ?? 0) * caloriesPerGram;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return _panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: MacroIcon(visual: visual, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$energy ${S.of(context).kcalLabel}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Semantics(
              label: label,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textInputAction: controller == _proteinController
                    ? TextInputAction.done
                    : TextInputAction.next,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'g',
                  isDense: true,
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                      borderSide: BorderSide(color: visual.color, width: 2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousDay() {
    final todayDate = _today();
    setState(() {
      final current = _dateOnly(_startDate);
      if (current.isAfter(todayDate)) {
        _startDate = current.subtract(const Duration(days: 1));
      }
      // Sinon, ne rien faire (reste sur aujourd'hui)
    });
  }

  void _goToNextDay() {
    setState(() {
      _startDate = _dateOnly(_startDate).add(const Duration(days: 1));
    });
  }

  Future<void> _selectDate() async {
    final todayDate = _today();
    final initial =
        _dateOnly(_startDate).isBefore(todayDate) ? todayDate : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: todayDate, // interdit toute date avant aujourd'hui
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = _dateOnly(picked); // normaliser
      });
    }
  }

  Future<void> _loadLatestGoal() async {
    try {
      // Déjà à true au démarrage; laisse tel quel
      final supabase = locator<SupabaseClient>();

      final history = <Map<String, dynamic>>[];
      for (var offset = 0;; offset += 500) {
        final page = await supabase
            .from('coach_macro_goals')
            .select()
            .eq('user_id', widget.studentId)
            .order('start_date', ascending: false)
            .range(offset, offset + 499)
            .timeout(const Duration(seconds: 8));
        history.addAll(page);
        if (page.length < 500) break;
      }
      _goalHistory = history.where(MacroGoalEntity.isValidHistoryRow).toList();
      final current = _goalHistory
          .where((row) => !DateTime.parse(row['start_date']).isAfter(_today()));
      final response = current.firstOrNull;

      if (mounted) {
        if (response != null) {
          final carbs = (response['carb_goal'] as num?)?.toInt();
          final fat = (response['fat_goal'] as num?)?.toInt();
          final protein = (response['protein_goal'] as num?)?.toInt();

          if (carbs != null) _carbsController.text = carbs.toString();
          if (fat != null) _fatController.text = fat.toString();
          if (protein != null) _proteinController.text = protein.toString();

          if (carbs != null && fat != null && protein != null) {
            _previousCalories = (carbs * 4) + (fat * 9) + (protein * 4);
          }
        } else {
          // Fallback aux valeurs passées au widget si aucun objectif trouvé
          _carbsController.text = widget.initialCarbs.toString();
          _fatController.text = widget.initialFat.toString();
          _proteinController.text = widget.initialProtein.toString();
        }
        _calculateCalories();
      }
    } catch (e, s) {
      // Ne bloque pas l'UI si échec; log via Crashlytics
      FirebaseCrashlytics.instance
          .recordError(e, s, reason: 'Load latest coach_macro_goals failed');
    } finally {
      if (mounted) setState(() => _loadingLatest = false);
    }
  }

  Future<void> _saveMacros() async {
    if (_saving || !_allFieldsFilled) return;
    setState(() => _saving = true);
    try {
      final supabase = locator<SupabaseClient>();

      final startDate = DateFormat('yyyy-MM-dd').format(_startDate);

      await saveCoachMacroGoal(supabase,
          studentId: widget.studentId,
          startDate: _startDate,
          carbs: int.parse(_carbsController.text),
          fat: int.parse(_fatController.text),
          protein: int.parse(_proteinController.text));

      if (!mounted) return;
      Navigator.pop(context, {
        'startDate': startDate,
        'carbsGoal': int.parse(_carbsController.text),
        'fatGoal': int.parse(_fatController.text),
        'proteinGoal': int.parse(_proteinController.text),
        'calorieGoal': _calculatedCalories,
      });
    } catch (exception, stacktrace) {
      log.warning("Erreur lors de l'enregistrement des objectifs macro.");
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).saveMacroGoalsError,
            ),
          ),
        );
      }
    }
  }
}
