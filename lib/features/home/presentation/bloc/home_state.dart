part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
}

class HomeInitial extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoadingState extends HomeState {
  @override
  List<Object?> get props => [];
}

class HomeLoadedState extends HomeState {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;
  final int dailySteps;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;
  final List<UserActivityEntity> userActivityList;
  final UserWeightEntity? userWeightEntity;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;
  final bool usesImperialUnits;

  const HomeLoadedState({
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
    required this.dailySteps,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
    required this.userActivityList,
    required this.userWeightEntity,
    required this.breakfastIntakeList,
    required this.lunchIntakeList,
    required this.dinnerIntakeList,
    required this.snackIntakeList,
    required this.usesImperialUnits,
  });

  HomeLoadedState copyWith({
    double? totalKcalDaily,
    double? totalKcalLeft,
    double? totalKcalSupplied,
    double? totalKcalBurned,
    int? dailySteps,
    double? totalCarbsIntake,
    double? totalFatsIntake,
    double? totalProteinsIntake,
    double? totalCarbsGoal,
    double? totalFatsGoal,
    double? totalProteinsGoal,
    List<UserActivityEntity>? userActivityList,
    UserWeightEntity? userWeightEntity,
    List<IntakeEntity>? breakfastIntakeList,
    List<IntakeEntity>? lunchIntakeList,
    List<IntakeEntity>? dinnerIntakeList,
    List<IntakeEntity>? snackIntakeList,
    bool? usesImperialUnits,
  }) {
    return HomeLoadedState(
      totalKcalDaily: totalKcalDaily ?? this.totalKcalDaily,
      totalKcalLeft: totalKcalLeft ?? this.totalKcalLeft,
      totalKcalSupplied: totalKcalSupplied ?? this.totalKcalSupplied,
      totalKcalBurned: totalKcalBurned ?? this.totalKcalBurned,
      dailySteps: dailySteps ?? this.dailySteps,
      totalCarbsIntake: totalCarbsIntake ?? this.totalCarbsIntake,
      totalFatsIntake: totalFatsIntake ?? this.totalFatsIntake,
      totalProteinsIntake:
          totalProteinsIntake ?? this.totalProteinsIntake,
      totalCarbsGoal: totalCarbsGoal ?? this.totalCarbsGoal,
      totalFatsGoal: totalFatsGoal ?? this.totalFatsGoal,
      totalProteinsGoal: totalProteinsGoal ?? this.totalProteinsGoal,
      userActivityList: userActivityList ?? this.userActivityList,
      userWeightEntity: userWeightEntity ?? this.userWeightEntity,
      breakfastIntakeList:
          breakfastIntakeList ?? this.breakfastIntakeList,
      lunchIntakeList: lunchIntakeList ?? this.lunchIntakeList,
      dinnerIntakeList: dinnerIntakeList ?? this.dinnerIntakeList,
      snackIntakeList: snackIntakeList ?? this.snackIntakeList,
      usesImperialUnits: usesImperialUnits ?? this.usesImperialUnits,
    );
  }

  @override
  List<Object?> get props => [
        dailySteps,
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList,
        usesImperialUnits
      ];
}
