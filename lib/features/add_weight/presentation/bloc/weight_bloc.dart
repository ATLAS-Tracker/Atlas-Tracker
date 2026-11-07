import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';

part 'weight_event.dart';

part 'weight_state.dart';

class WeightBloc extends Bloc<WeightEvent, WeightState> {
  final GetWeightUsecase _getWeightUsecase = locator<GetWeightUsecase>();

  final log = Logger('WeightBloc');

  final double weightStep = 0.1;
  final double maxWeight = 400;

  WeightBloc() : super(WeightState(0.0)) {
    on<WeightLoadInitialRequested>((event, emit) async {
      try {
        // Fetch the last known weight from the use case.
        final fetchedLastWeight =
            await _getWeightUsecase.getLastUserWeight(event.date);

        double weightToEmit = fetchedLastWeight;

        log.fine('Initial user weight: $weightToEmit');
        emit(WeightState(weightToEmit));
      } catch (e, stackTrace) {
        log.severe('Failed to load initial weight', e, stackTrace);
      }
    });

    on<WeightIncrement>((event, emit) {
      double currentWeight = state.weight;
      double finalWeight = currentWeight + weightStep;
      emit(WeightState(finalWeight > maxWeight ? maxWeight : finalWeight));
    });
    on<WeightDecrement>((event, emit) {
      double currentWeight = state.weight;
      double finalWeight =
          (currentWeight - weightStep) > 0 ? currentWeight - weightStep : 0.0;
      emit(WeightState(finalWeight));
    });
    on<WeightSet>((event, emit) {
      double weightToEmit = event.weight;
      if (!weightToEmit.isFinite) return;
      if (weightToEmit < 0) weightToEmit = 0.0;
      if (weightToEmit > maxWeight) weightToEmit = maxWeight;
      emit(WeightState(weightToEmit));
    });
  }
}
