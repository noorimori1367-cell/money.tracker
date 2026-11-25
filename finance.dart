import 'package:decimal/decimal.dart';

typedef RowData = Map<String, Object?>;
Decimal number(Object? v) => Decimal.parse(v.toString());
final zero = Decimal.zero;
Decimal divide(Decimal a, Decimal b) =>
    (a / b).toDecimal(scaleOnInfinitePrecision: 24);

class Holding {
  Decimal quantity = Decimal.zero, cost = Decimal.zero, realized = Decimal.zero;
}

abstract class CostMethod {
  Decimal soldCost(Holding h, Decimal qty);
}

class MovingAverage implements CostMethod {
  @override
  Decimal soldCost(Holding h, Decimal qty) =>
      qty == h.quantity ? h.cost : divide(h.cost * qty, h.quantity);
}

// Rows must be in effective date and entry order.
Map<String, Holding> replay(Iterable<RowData> rows, {CostMethod? method}) {
  final holdings = <String, Holding>{};
  for (final row in rows) {
    final h = holdings.putIfAbsent(row['asset'] as String, Holding.new);
    final qty = number(row['qty']), fee = number(row['fee']);
    final gross = qty * number(row['price']) * number(row['fx']);
    if (row['side'] == 'خرید') {
      h.quantity += qty;
      h.cost += gross + fee;
    } else {
      if (qty > h.quantity) throw const FormatException('فروش از موجودی همان روز بیشتر است.');
      final sold = (method ?? MovingAverage()).soldCost(h, qty);
      h.realized += gross - fee - sold;
      h.cost -= sold;
      h.quantity -= qty;
    }
  }
  return holdings;
}
