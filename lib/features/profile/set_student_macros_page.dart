import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging/logging.dart';

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
    _carbsController =
        TextEditingController(text: widget.initialCarbs.toString());
    _fatController = TextEditingController(text: widget.initialFat.toString());
    _proteinController =
        TextEditingController(text: widget.initialProtein.toString());
    _calculateCalories();

    _carbsController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);
    _proteinController.addListener(_calculateCalories);
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
    final todayDate = _today();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(S.of(context).setMacrosLabel)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de date
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    // Désactive si on est déjà sur aujourd'hui (ou avant, par sécurité)
                    onPressed: _dateOnly(_startDate).isAfter(todayDate)
                        ? _goToPreviousDay
                        : null,
                  ),
                  InkWell(
                    onTap: _selectDate,
                    child: Row(
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_startDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goToNextDay,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Glucides
              TextFormField(
                controller: _carbsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: S.of(context).carbsLabel,
                ),
              ),
              const SizedBox(height: 16),

              // Lipides
              TextFormField(
                controller: _fatController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: S.of(context).fatLabel,
                ),
              ),
              const SizedBox(height: 16),

              // Protéines
              TextFormField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: S.of(context).proteinLabel,
                ),
              ),
              const SizedBox(height: 24),

              // Calories affichées
              Center(
                child: Text(
                  '${S.of(context).caloriesLabel}: $_calculatedCalories kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // Bouton Enregistrer
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveMacros,
                  child: Text(S.of(context).buttonSaveLabel),
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _saveMacros() async {
    try {
      final supabase = locator<SupabaseClient>();
      final json = {
        'user_id': widget.studentId,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'calorie_goal': _calculatedCalories,
        'carb_goal': int.parse(_carbsController.text),
        'fat_goal': int.parse(_fatController.text),
        'protein_goal': int.parse(_proteinController.text),
      };

      await supabase
          .from('coach_macro_goals')
          .upsert(json, onConflict: 'user_id');

      if (!mounted) return;
      Navigator.pop(context);
    } catch (exception, stacktrace) {
      log.warning("Erreur lors de l'enregistrement des objectifs macro.");
      FirebaseCrashlytics.instance.recordError(exception, stacktrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Problème lors de l'enregistrement des objectifs macro.",
            ),
          ),
        );
      }
    }
  }
}
