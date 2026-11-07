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

  const StudentMacrosLoaded({
    required this.macros,
    this.targetWeight,
    required this.selectedDate,
  });

  StudentMacrosLoaded copyWith({
    Map<String, Map<String, dynamic>>? macros,
    DateTime? selectedDate,
  }) {
    return StudentMacrosLoaded(
      macros: macros ?? this.macros,
      targetWeight: targetWeight,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [macros, targetWeight, selectedDate];
}

class StudentMacrosError extends StudentMacrosState {
  final String message;
  const StudentMacrosError(this.message);
  @override
  List<Object?> get props => [message];
}
