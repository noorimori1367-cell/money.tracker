import 'package:flutter_test/flutter_test.dart';
import 'package:sahm/finance.dart';

void main(){
  RowData row(String side,String price,String fee)=>{'asset':'coin','side':side,'qty':'1','price':price,'fee':fee,'fx':'1'};
  test('moving average includes fees on both sides',(){
    final h=replay([row('خرید','40','2'),row('خرید','60','2'),row('فروش','70','1')])['coin']!;
    expect(h.quantity,number('1'));
    expect(h.cost,number('52'));
    expect(h.realized,number('17'));
  });
  test('cannot sell before a purchase',(){
    expect(()=>replay([row('فروش','70','0')]),throwsFormatException);
  });
}
