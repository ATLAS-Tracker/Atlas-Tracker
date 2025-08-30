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
    emit(StudentMacrosLoading());
    try {
      final macros = await _fetchMacros(event.studentId);
      emit(
        StudentMacrosLoaded(
          macros: macros,
          selectedDate: DateTime.now(),
          selectedMacro: MacroType.calories,
          selectedRange: TimeRange.week,
        ),
      );
    } catch (e) {
      emit(StudentMacrosError(e.toString()));
    }
  }

  void _onChangeDate(
    ChangeDateEvent event,
    Emitter<StudentMacrosState> emit,
  ) {
    final current = state;
    if (current is StudentMacrosLoaded) {
      emit(current.copyWith(selectedDate: event.date));
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

    final stepsResponse = await _supabase
        .from('daily_steps')
        .select('date, steps')
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

    for (final Map<String, dynamic> item in stepsResponse) {
      final dateStr = item['date'] as String;
      result.putIfAbsent(dateStr, () => {});
      result[dateStr]!['steps'] = item['steps'];
    }

    return result;
  }
}
