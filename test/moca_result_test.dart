import 'package:flutter_test/flutter_test.dart';
import 'package:ihsana/scoring/moca_result.dart';

void main() {
  test('Moca score calculation and classification', () {
    final result = MocaResult(
      visuospatial: 5,
      naming: 3,
      attention: 6,
      language: 3,
      abstraction: 2,
      delayedRecall: 5,
      orientation: 6,
      educationBelow12Years: false,
    );

    expect(result.totalScore, 30);
    expect(result.classification, CognitiveStatus.normal);
  });
}
