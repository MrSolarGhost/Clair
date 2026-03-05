import 'package:flutter_test/flutter_test.dart';
import 'package:clair/services/core_matrix.dart';

void main() {
  test('core matrix maps system to core', () {
    expect(CoreMatrix.coreForSystem('SNES'), isNotNull);
  });
}
