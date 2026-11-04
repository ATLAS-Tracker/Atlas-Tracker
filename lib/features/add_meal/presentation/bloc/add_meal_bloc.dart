import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_meal_event.dart';

part 'add_meal_state.dart';

class AddMealBloc extends Bloc<AddMealEvent, AddMealState> {
  AddMealBloc() : super(AddMealInitialState()) {
    on<InitializeAddMealEvent>((event, emit) async {
      emit(AddMealLoadingState());

      emit(const AddMealLoadedState());
    });
  }
}
