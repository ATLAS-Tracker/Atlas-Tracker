import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'student_macros_event.dart';
part 'student_macros_state.dart';

enum MacroType { calories, carbs, fat, protein, weight, steps }

enum TimeRange { week, month, threeMonths, sixMonths, year }

class StudentMacrosBloc extends Bloc<StudentMacrosEvent, StudentMacrosState> {
  final SupabaseClient _supabase;

  StudentMacrosBloc(this._supabase) : super(StudentMacrosInitial()) {
    on<LoadStudentMacrosEvent>(_onLoad);
    on<ChangeDateEvent>(_onChangeDate);
    on<ChangeMacroTypeEvent>(_onChangeMacro);
    on<ChangeRangeEvent>(_onChangeRange);
    on<UpdateDayMacrosEvent>(_onUpdateDayMacros);
  }

  Future<void> _onLoad(
    LoadStudentMacrosEvent event,
    Emitter<StudentMacrosState> emit,
  ) async {
    final previous = state;
    // Rafraîchissement : garde l'écran et la date affichés.
    if (previous is! StudentMacrosLoaded) emit(StudentMacrosLoading());
    try {
      final (macros, targetWeight) = await (
        _fetchMacros(event.studentId),
        _fetchTargetWeight(event.studentId),
      ).wait;
      emit(
        StudentMacrosLoaded(
          macros: macros,
          targetWeight: targetWeight,
          selectedDate: previous is StudentMacrosLoaded
              ? previous.selectedDate
              : DateTime.now(),
          selectedMacro: MacroType.calories,
          selectedRange: TimeRange.week,
        ),
      );
    } catch (e) {
      emit(StudentMacrosError(e.toString()));
    } finally {
      event.done?.complete();
    }
  }

  void _onChangeDate(
    ChangeDateEvent event,
    Emitter<StudentMacrosState> emit,
  ) {
    final current = state;
    if (current is StudentMacrosLoaded) {
      final now = DateTime.now();
      final todayOnly = DateTime(now.year, now.month, now.day);
      final d = event.date;
      final incomingOnly = DateTime(d.year, d.month, d.day);
      final safeDate =
          incomingOnly.isAfter(todayOnly) ? todayOnly : incomingOnly;
      emit(current.copyWith(selectedDate: safeDate));
    }
  }

  void _onChangeMacro(
    ChangeMacroTypeEvent event,
    Emitter<StudentMacrosState> emit,
  ) {
    final current = state;
    if (current is StudentMacrosLoaded) {
      emit(current.copyWith(selectedMacro: event.macro));
    }
  }

  void _onChangeRange(
    ChangeRangeEvent event,
    Emitter<StudentMacrosState> emit,
  ) {
    final current = state;
    if (current is StudentMacrosLoaded) {
      emit(current.copyWith(selectedRange: event.range));
    }
  }

  void _onUpdateDayMacros(
    UpdateDayMacrosEvent event,
    Emitter<StudentMacrosState> emit,
  ) {
    final current = state;
    if (current is StudentMacrosLoaded) {
      final newMacros = Map<String, Map<String, dynamic>>.from(current.macros);
      final existing = Map<String, dynamic>.from(newMacros[event.dayKey] ?? {});
      existing.addAll(event.data);
      newMacros[event.dayKey] = existing;
      emit(current.copyWith(macros: newMacros));
    }
  }

  /// Poids cible du profil élève (users.weight_kg, comme sur l'accueil).
  Future<double?> _fetchTargetWeight(String studentId) async {
    final row = await _supabase
        .from('users')
        .select('weight_kg')
        .eq('id', studentId)
        .maybeSingle();
    return (row?['weight_kg'] as num?)?.toDouble();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchMacros(
    String studentId,
  ) async {
    final now = DateTime.now();
    final startDate = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 365)));
    final endDate = DateFormat('yyyy-MM-dd').format(now);

    final macroResponse = await _supabase
        .from('tracked_days')
        .select(
          'day, calorieGoal, caloriesTracked, caloriesBurned, carbsGoal, carbsTracked, fatGoal, fatTracked, proteinGoal, proteinTracked',
        )
        .eq('user_id', studentId)
        .gte('day', startDate)
        .lte('day', endDate)
        .order('day');

    final weightResponse = await _supabase
        .from('user_weight')
        .select('date, weight')
        .eq('user_id', studentId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date');

    final Map<String, Map<String, dynamic>> result = {
      for (final Map<String, dynamic> item in macroResponse)
        item['day'] as String: item,
    };

    for (final Map<String, dynamic> item in weightResponse) {
      final dateStr = item['date'] as String;
      result.putIfAbsent(dateStr, () => {});
      result[dateStr]!['weight'] = item['weight'];
    }

    return result;
  }
}
