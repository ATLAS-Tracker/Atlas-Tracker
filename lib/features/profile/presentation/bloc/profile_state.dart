part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  @override
  List<Object> get props => [];
}

class ProfileLoadingState extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileErrorState extends ProfileState {
  final String message;

  const ProfileErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileLoadedState extends ProfileState {
  final UserBMIEntity userBMI;
  final UserEntity userEntity;

  final bool usesImperialUnits;

  const ProfileLoadedState(
      {required this.userBMI,
      required this.userEntity,
      required this.usesImperialUnits});

  @override
  List<Object?> get props => [userBMI, userEntity, usesImperialUnits];
}
