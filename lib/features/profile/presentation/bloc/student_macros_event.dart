part of 'student_macros_bloc.dart';

abstract class StudentMacrosEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadStudentMacrosEvent extends StudentMacrosEvent {
  final String studentId;

  /// Complété à la fin du chargement (tirer pour rafraîchir).
  final Completer<void>? done;
  LoadStudentMacrosEvent(this.studentId, {this.done});
  @override
  List<Object?> get props => [studentId];
}

class ChangeDateEvent extends StudentMacrosEvent {
  final DateTime date;
  ChangeDateEvent(this.date);
  @override
  List<Object?> get props => [date];
}

class ChangeMacroTypeEvent extends StudentMacrosEvent {
  final MacroType macro;
  ChangeMacroTypeEvent(this.macro);
  @override
  List<Object?> get props => [macro];
}

class ChangeRangeEvent extends StudentMacrosEvent {
  final TimeRange range;
  ChangeRangeEvent(this.range);
  @override
  List<Object?> get props => [range];
}

class UpdateDayMacrosEvent extends StudentMacrosEvent {
  final String dayKey;
  final Map<String, dynamic> data;
  UpdateDayMacrosEvent(this.dayKey, this.data);
  @override
  List<Object?> get props => [dayKey, data];
}
