part of 'edit_meal_bloc.dart';

abstract class EditMealState extends Equatable {
  const EditMealState();
}

class EditMealInitial extends EditMealState {
  @override
  List<Object> get props => [];
}

class EditMealLoadingState extends EditMealState {
  @override
  List<Object?> get props => [];
}

class EditMealLoadedState extends EditMealState {
  const EditMealLoadedState();

  @override
  List<Object?> get props => [];
}
