part of 'recent_meal_bloc.dart';

abstract class RecentMealState extends Equatable {
  const RecentMealState();
}

class RecentMealInitial extends RecentMealState {
  @override
  List<Object> get props => [];
}

class RecentMealLoadingState extends RecentMealState {
  @override
  List<Object?> get props => [];
}

class RecentMealLoadedState extends RecentMealState {
  final List<MealEntity> recentMeals;
  final Map<String, IntakeEntity> lastIntakes;

  const RecentMealLoadedState(
      {required this.recentMeals, this.lastIntakes = const {}});

  @override
  List<Object?> get props => [recentMeals, lastIntakes];
}

class RecentMealFailedState extends RecentMealState {
  @override
  List<Object?> get props => [];
}
