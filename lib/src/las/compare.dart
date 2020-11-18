import '../mymath.dart';

import 'index.dart';

extension LasExtCompare on Las {
  /// Возвращает процент похожести данных
  double compare(Las las) {
    if (well == las.well) {
      var k = 0;
      var o = 0.0;
      for (var c1 in curves) {
        for (var c2 in las.curves) {
          o += c1.compare(c2);
        }
      }
      return o / k.toDouble();
    }
    return 0.0;
  }
}

extension LasCurveExtCompare on LasCurve {
  /// Возвращает процент похожести данных
  double compare(LasCurve c) {
    if (data.length == c.data.length) {
      final _l = data.length;
      var k = 0;
      if (doubleEqual(strt, c.strt) && doubleEqual(stop, c.stop)) {
        for (var i = 0; i < _l; i++) {
          if (doubleEqual(data[i], c.data[i])) {
            k++;
          }
        }
      } else if (doubleEqual(strt, c.stop) && doubleEqual(stop, c.strt)) {
        for (var i = 0; i < _l; i++) {
          if (doubleEqual(data[_l - i - 1], c.data[i])) {
            k++;
          }
        }
      }
      return k.toDouble() / _l.toDouble();
    }
    return 0.0;
  }
}
