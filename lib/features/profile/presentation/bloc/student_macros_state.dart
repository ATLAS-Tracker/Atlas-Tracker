part of 'student_macros_bloc.dart';

abstract class StudentMacrosState extends Equatable {
  const StudentMacrosState();
}

class StudentMacrosInitial extends StudentMacrosState {
  @override
  List<Object?> get props => [];
}

class StudentMacrosLoading extends StudentMacrosState {
  @override
  List<Object?> get props => [];
}

class StudentMacrosLoaded extends StudentMacrosState {
  final Map<String, Map<String, dynamic>> macros;
  final double? targetWeight;
  final DateTime selectedDate;
  final MacroType selectedMacro;
  final TimeRange selectedRange;

  const StudentMacrosLoaded({
    required this.macros,
    this.targetWeight,
    required this.selectedDate,
    required this.selectedMacro,
    required this.selectedRange,
  });

  StudentMacrosLoaded copyWith({
    Map<String, Map<String, dynamic>>? macros,
    DateTime? selectedDate,
    MacroType? selectedMacro,
    TimeRange? selectedRange,
  }) {
    return StudentMacrosLoaded(
      macros: macros ?? this.macros,
      targetWeight: targetWeight,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedMacro: selectedMacro ?? this.selectedMacro,
      selectedRange: selectedRange ?? this.selectedRange,
    );
  }

  @override
  List<Object?> get props =>
      [macros, targetWeight, selectedDate, selectedMacro, selectedRange];
}

class StudentMacrosError extends StudentMacrosState {
  final String message;
  const StudentMacrosError(this.message);
  @override
  List<Object?> get props => [message];
}
