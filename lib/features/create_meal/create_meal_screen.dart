import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/features/create_meal/create_meal_modal.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/create_meal/pick_image_screen.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

class MealCreationScreen extends StatefulWidget {
  const MealCreationScreen({super.key});

  @override
  State<MealCreationScreen> createState() => _MealCreationScreenState();
}

class _MealCreationScreenState extends State<MealCreationScreen> {
  final log = Logger('MealCreationScreen');
  late final CreateMealBloc _createMealBloc;
  final _nameTextController = TextEditingController();
  String? _imagePath;
  bool _isDragging = false;
  late String _id = "";
  late String _name = "";
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _createMealBloc = locator<CreateMealBloc>();
    _createMealBloc.add(InitializeCreateMealEvent());
    log.info(
      "InitializeCreateMealEvent added: isOnCreateMealScreen set to true",
    );
  }

  @override
  void dispose() {
    _createMealBloc.add(ExitCreateMealScreenEvent());
    log.info(
      "ExitCreateMealScreenEvent added: isOnCreateMealScreen set to false",
    );
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    _isInitialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is CreateMealScreenArguments) {
      _id = args.id;
      _name = args.name;
      _nameTextController.text = _name;
      _imagePath = args.imagePath;

      // Envoie les ingrédients au bloc de façon réactive (déclenche UI update)
      _createMealBloc.add(
        SetIntakeListFromRecipeEvent(args.recipe.ingredients),
      );
    } else {
      _id = UniqueKey().toString();
      _name = "";
      _nameTextController.text = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).recipeLabel),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: BlocBuilder<CreateMealBloc, CreateMealState>(
                bloc: _createMealBloc,
                builder: (context, state) {
                  final isButtonEnabled =
                      _nameTextController.text.trim().isNotEmpty &&
                          state.intakeList.isNotEmpty;

                  return FilledButton(
                    onPressed:
                        isButtonEnabled ? () => _onSavePressed(true) : null,
                    child: Text(S.of(context).buttonSaveLabel),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameTextController,
                                decoration: InputDecoration(
                                  labelText: S.of(context).mealNameLabel,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(
                                      6.0,
                                    ),
                                    child: PhotoPickerButton(
                                      initialImagePath: _imagePath,
                                      onImagePicked: (imagePath) {
                                        setState(() {
                                          _imagePath = imagePath;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<CreateMealBloc, CreateMealState>(
                          bloc: _createMealBloc,
                          builder: (context, state) {
                            final intakeList = state.intakeList;

                            if (intakeList.isEmpty) {
                              return Text(S.of(context).noFoodAddedLabel);
                            }

                            final now = DateTime.now();
                            final convertedIntakeList =
                                state.intakeList.map((ingredient) {
                              return IntakeEntity(
                                id: ingredient.code ?? ingredient.name ?? "",
                                unit: ingredient.unit ?? "g",
                                amount: ingredient.amount ?? 0,
                                type: IntakeTypeEntity.breakfast,
                                meal: ingredient.meal!,
                                dateTime: now,
                                updatedAt: DateTime.now().toUtc(),
                              );
                            }).toList();

                            return Column(
                              children: [
                                IntakeVerticalList(
                                  day: DateTime.now(),
                                  title: "",
                                  addMealType: AddMealType
                                      .snackType, // TODO Pierre refactor
                                  listIcon: Icons.functions,
                                  intakeList: convertedIntakeList,
                                  onDeleteIntakeCallback: _onDeleteIntakeItem,
                                  onItemDragCallback: onIntakeItemDrag,
                                  onItemTappedCallback: onIntakeItemTapped,
                                  usesImperialUnits: false,
                                  isDropZone: false,
                                ),
                                const SizedBox(height: 32),
                                if (state.totalCarbs +
                                        state.totalFats +
                                        state.totalProteins >
                                    0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Center(
                                      child: PieChart(
                                        dataMap: {
                                          'Protéine': state.totalProteins,
                                          'Glucide': state.totalCarbs,
                                          'Lipide': state.totalFats,
                                        },
                                        animationDuration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        chartLegendSpacing: 32,
                                        chartRadius: MediaQuery.of(
                                              context,
                                            ).size.width /
                                            2.5,
                                        colorList: [
                                          proteinColor.withValues(alpha: 0.75),
                                          carbColor.withValues(alpha: 0.75),
                                          fatColor.withValues(alpha: 0.75),
                                        ],
                                        initialAngleInDegree: 0,
                                        chartType: ChartType.ring,
                                        ringStrokeWidth: 32,
                                        centerText: "",
                                        legendOptions: const LegendOptions(
                                          showLegendsInRow: false,
                                          legendPosition: LegendPosition.bottom,
                                          showLegends: true,
                                          legendShape: BoxShape.circle,
                                          legendTextStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        chartValuesOptions:
                                            const ChartValuesOptions(
                                          showChartValueBackground: true,
                                          showChartValues: true,
                                          showChartValuesInPercentage: false,
                                          showChartValuesOutside: true,
                                          decimalPlaces: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Visibility(
                      visible: _isDragging,
                      child: Container(
                        height: 70,
                        color: Theme.of(
                          context,
                        ).colorScheme.error,
                        child: DragTarget<IntakeEntity>(
                          onAcceptWithDetails: (details) {
                            _confirmDelete(context, details.data);
                          },
                          onLeave: (data) {
                            setState(() {
                              _isDragging = false;
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return const Center(
                              child: Icon(
                                Icons.delete_outline,
                                size: 36,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemScreen(
            context,
            AddMealType.snackType,
            DateTime.now(),
          ),
          tooltip: S.of(context).addLabel,
          shape: const CircleBorder(),
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          disabledElevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void onIntakeItemDrag(bool isDragging) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDragging = isDragging;
      });
    });
  }

  void onIntakeItemTapped(
    BuildContext context,
    IntakeEntity intakeEntity,
    bool usesImperialUnits,
  ) async {
    final dialogResult = await showDialog<EditDialogResult>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
        usesImperialUnits: usesImperialUnits,
      ),
    );

    if (dialogResult == null) {
      return;
    }

    switch (dialogResult.action) {
      case EditDialogAction.updateAmount:
        final updatedAmount = dialogResult.amount;
        if (updatedAmount == null) {
          return;
        }
        locator<CreateMealBloc>().updateIntakeAmount(
          intakeEntity.id,
          updatedAmount,
        );
        break;
      case EditDialogAction.deleteItem:
        locator<CreateMealBloc>().removeIntake(intakeEntity.id);
        break;
      case EditDialogAction.viewProduct:
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pushNamed(
          NavigationOptions.mealDetailRoute,
          arguments: MealDetailScreenArguments(
            intakeEntity.meal,
            intakeEntity.type,
            intakeEntity.dateTime,
            usesImperialUnits,
          ),
        );
        break;
    }
  }

  void _showAddItemScreen(
    BuildContext context,
    AddMealType itemType,
    DateTime day,
  ) {
    Navigator.of(context).pushNamed(
      NavigationOptions.addMealRoute,
      arguments: AddMealScreenArguments(
        itemType,
        day,
        MealOrRecipeEntity.recipe,
      ),
    );
  }

  void _confirmDelete(BuildContext context, IntakeEntity intake) async {
    bool? delete = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (delete == true) {
      locator<CreateMealBloc>().removeIntake(intake.id);
    }
    setState(() {
      _isDragging = false;
    });
  }

  void _onDeleteIntakeItem(
    IntakeEntity intakeEntity,
    TrackedDayEntity? trackedDayEntity,
  ) {}

  void _onSavePressed(bool usesImperialUnits) {
    final recipeName = _nameTextController.text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return CalendarMealTypeSelector(
          onDateSelected: (date) {},
          mealName: recipeName,
          idOfRecipeToModify: _id,
          imagePath: _imagePath,
        );
      },
    );
  }
}

class CreateMealScreenArguments {
  final String id;
  final String name;
  final RecipeEntity recipe;
  final String? imagePath;
  CreateMealScreenArguments(this.id, this.name, this.recipe, this.imagePath);
}
