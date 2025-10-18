import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/presentation/constants/app_icons.dart';

class WeightCard extends StatefulWidget {
  final double weight;
  final VoidCallback onTap;
  final Function(BuildContext) onLongTap;
  final DateTime day;

  const WeightCard(
      {super.key,
      required this.weight,
      required this.onTap,
      required this.onLongTap,
      required this.day});

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard> {
  final GetWeightUsecase _getWeightUsecase = locator<GetWeightUsecase>();
  double delta = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topLeft,
        child: Row(
          children: [
            SizedBox(
              width: 16,
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: Card(
                elevation: 0,
                shadowColor: Colors.transparent,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: () => widget.onLongTap(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("${widget.weight.toStringAsFixed(1)} kg",
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8.0),
                      // Asynchronously builds the UI to show the weight delta
                      // compared to the N-days average. Displays an icon
                      // indicating if the current weight is higher, lower, or
                      // the same as the average, along with the numerical delta.
                      FutureBuilder<double>(
                        future:
                            _getWeightUsecase.getAverageWeight(widget.day, 7),
                        builder: (BuildContext context,
                            AsyncSnapshot<double> snapshot) {
                          if (snapshot.hasData) {
                            final avgWeight = snapshot.data!;
                            delta = widget.weight - avgWeight;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.getIconForDifference(
                                      widget.weight, avgWeight),
                                  size: 25,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  "${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            );
                          }
                          // Fallback, though ideally not reached if future resolves correctly
                          return const Icon(Icons.horizontal_rule);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
