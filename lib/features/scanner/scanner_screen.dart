import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

import 'package:opennutritracker/features/scanner/presentation/widget/missing_nutrients_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final log = Logger('ScannerScreen');

  String? _scannedBarcode;
  late IntakeTypeEntity _intakeTypeEntity;
  late DateTime _day;

  late ScannerBloc _scannerBloc;
  late MobileScannerController _cameraController;
  bool _scanInFlight = false;
  bool _navigating = false;

  @override
  void initState() {
    _scannerBloc = locator<ScannerBloc>();
    _cameraController = MobileScannerController();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _scannerBloc.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ScannerScreenArguments;
    _intakeTypeEntity = args.intakeTypeEntity;
    _day = args.day;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerBloc, ScannerState>(
      bloc: _scannerBloc,
      builder: (context, state) {
        if (state is ScannerInitial) {
          return _getScannerContent(context);
        } else if (state is ScannerLoadingState) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        } else if (state is ScannerLoadedState) {
          if (_navigating) return const SizedBox();
          _navigating = true;
          // Push new route after build
          Future.microtask(() {
            if (!context.mounted) return;

            final void Function(BuildContext)? postNavigationAction =
                !state.product.hasNutriments
                    ? (BuildContext newContext) {
                        showDialog(
                          barrierDismissible: false,
                          context: newContext,
                          builder: (BuildContext dialogContext) {
                            return MissingNutrientsDialog(
                                day: _day,
                                mealEntity: state.product,
                                intakeTypeEntity: _intakeTypeEntity);
                          },
                        );
                      }
                    : null;

            final arguments = MealDetailScreenArguments(
              state.product,
              _intakeTypeEntity,
              _day,
              postNavigationAction: postNavigationAction,
            );

            // Navigate
            Navigator.of(context).pushReplacementNamed(
              NavigationOptions.mealDetailRoute,
              arguments: arguments,
            );
          });
        } else if (state is ScannerFailedState) {
          return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ErrorDialog(
                    errorText:
                        state.type == ScannerFailedStateType.productNotFound
                            ? S.of(context).errorProductNotFound
                            : S.of(context).errorFetchingProductData,
                    onRefreshPressed: _onRefreshButtonPressed,
                  ),
                  TextButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(S.of(context).customFoodTitle),
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(NavigationOptions.editMealRoute,
                              arguments: EditMealScreenArguments(
                                  _day,
                                  MealEntity.empty()
                                      .copyWith(code: _scannedBarcode),
                                  _intakeTypeEntity))),
                ]),
              ));
        }
        return const SizedBox();
      },
    );
  }

  Scaffold _getScannerContent(BuildContext context) {
    final cameraController = _cameraController;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).scanProductLabel),
        actions: [
          IconButton(
            tooltip: S.of(context).toggleFlashLabel,
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off || TorchState.unavailable:
                    return const Icon(Icons.flash_off_outlined,
                        color: Colors.grey);
                  case TorchState.on || TorchState.auto:
                    return const Icon(Icons.flash_on_outlined);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            tooltip: S.of(context).switchCameraLabel,
            icon: const Icon(Icons.flip_camera_android_outlined),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            if (_scanInFlight) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null &&
                  barcode.type == BarcodeType.product) {
                final barcodeResult = barcode.rawValue;
                if (barcodeResult != null) {
                  _scanInFlight = true;
                  _scannedBarcode = barcodeResult;
                  log.fine('Barcode found: $barcodeResult');
                  _scannerBloc
                      .add(ScannerLoadProductEvent(barcode: barcodeResult));
                  break;
                }
              }
            }
          }),
    );
  }

  void _onRefreshButtonPressed() {
    final barcode = _scannedBarcode;
    if (barcode != null) {
      _scannerBloc.add(ScannerLoadProductEvent(barcode: barcode));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorFetchingProductData)));
    }
  }
}

class ScannerScreenArguments {
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;

  ScannerScreenArguments(this.day, this.intakeTypeEntity);
}
