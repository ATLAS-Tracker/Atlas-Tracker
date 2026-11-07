import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

void main() {
  test('food units only offer metric units and portions', () {
    expect(UnitDropdownItem.values.map((unit) => unit.toString()).toList(),
        ['g', 'ml', 'serving']);
  });

  test('legacy food unit labels resolve to their stored metric base', () {
    expect(UnitDropdownItem.g.fromString('oz'), UnitDropdownItem.g);
    expect(UnitDropdownItem.g.fromString('fl.oz'), UnitDropdownItem.ml);
  });
}
