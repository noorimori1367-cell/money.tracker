import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:uuid/uuid.dart';
import 'finance.dart';
import 'store.dart';

const markets = {'بورس ایران':'سهم','سهام دلاری':'سهم','ارز دیجیتال':'واحد','طلای فیزیکی':'گرم','طلای جهانی':'اونس تروا','نقرهٔ فیزیکی':'گرم','سکه':'قطعه','ارز':'واحد','صندوق':'واحد','ملک':'واحد','سپرده بانکی':'واحد','سایر':'واحد'};
String fa(Object x)=> x.toString().replaceAllMapped(RegExp('[0-9]'),(m)=>'۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);
String normal(String x)=>x.trim().replaceAllMapped(RegExp('[۰-۹]'),(m)=>'۰۱۲۳۴۵۶۷۸۹'.indexOf(m[0]!).toString()).replaceAll('٬','').replaceAll(',','').replaceAll('٫','.');
Jalali today()=>Jalali.fromDateTime(DateTime.now().toUtc().add(const Duration(hours:3,minutes:30)));
String display(Jalali d)=>fa('${d.day} ${d.formatter.mN} ${d.year}');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {final store=await Store.open();runApp(App(store));} catch(e){runApp(MaterialApp(home:Scaffold(body:Center(child:Text('خطا در باز کردن دفتر محلی: $e')))));}
}
class App extends StatefulWidget {
  final Store store; const App(this.store,{super.key});
  @override State<App> createState()=>_AppState();
}
class _AppState extends State<App>{
 bool dark=false;
 @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,locale:const Locale('fa'),supportedLocales:const [Locale('fa')],localizationsDelegates:GlobalMaterialLocalizations.delegates,theme:ThemeData(fontFamily:'Naskh',colorSchemeSeed:const Color(0xff465eac),brightness:dark?Brightness.dark:Brightness.light),home:Home(widget.store,()=>setState(()=>dark=!dark)));
}
class Home extends StatefulWidget {
 final Store store;final VoidCallback theme; const Home(this.store,this.theme,{super.key});
 @override State<Home> createState()=>_Home();
}
class _Home extends State<Home>{
 final fields=List.generate(7,(_)=>TextEditingController());
 String market=markets.keys.first, side='خرید',currency='تومان';String? editing;
 Jalali day=today();List<RowData> rows=[],quotes=[];String message='';bool intro=true,busy=false;
 String get asset=>jsonEncode([market,fields[0].text.trim(),fields[6].text.trim()]);
 @override void initState(){super.initState();clear();refresh();Future.delayed(const Duration(milliseconds:2300),(){if(mounted)setState(()=>intro=false);});}
 @override void dispose(){for(final c in fields){c.dispose();}super.dispose();}
 Future<void> refresh()async{final r=await widget.store.trades(widget.store.db);final q=await widget.store.db.query('quotes',orderBy:'rowid');if(mounted)setState((){rows=r;quotes=q;});}
 void clear(){editing=null;day=today();side='خرید';currency=['طلای جهانی','سهام دلاری'].contains(market)?'دلار':'تومان';for(final c in fields){c.clear();}fields[3].text='0';fields[4].text='1';}
 String val(int i,{bool allowZero=false}){final v=number(normal(fields[i].text));if(v<zero||(!allowZero&&v==zero))throw const FormatException('مقدار نامعتبر');return v.toString();}
 Future<void> action(Future<void> Function() fn)async{if(busy)return;setState(()=>busy=true);try{await fn();await refresh();message='تغییرات ذخیره شد';}catch(e){message='ثبت انجام نشد: $e';}finally{if(mounted)setState(()=>busy=false);}}
 Future<void> save(bool quote)async{
 if(fields[0].text.trim().isEmpty)throw const FormatException('نام دارایی را وارد کن');
 final stamp=DateTime.now().toUtc().toIso8601String(),fx=currency=='تومان'?'1':val(4);
 if(quote){await widget.store.db.insert('quotes',{'id':const Uuid().v4(),'asset':asset,'price':val(2),'currency':currency,'fx':fx,'updated':stamp});return;}
 await widget.store.save({'id':editing??const Uuid().v4(),'asset':asset,'qty':val(1),'price':val(2),'fee':val(3,allowZero:true),'fx':fx,'side':side,'currency':currency,'day':day.julianDayNumber,'updated':stamp,'note':fields[5].text});clear();
 }
 void edit(RowData r){final a=jsonDecode(r['asset'] as String);setState((){market=a[0];fields[0].text=a[1];fields[6].text=a[2];for(final p in {1:'qty',2:'price',3:'fee',4:'fx',5:'note'}.entries){fields[p.key].text=r[p.value].toString();}editing=r['id'] as String;side=r['side'] as String;currency=r['currency'] as String;day=Jalali.fromJulianDayNumber(r['day'] as int);});}
 Future<void> calendar() async{var month=Jalali(day.year,day.month,1);final d=await showDialog<Jalali>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(title:Text(fa('${month.formatter.mN} ${month.year}')),content:SizedBox(width:320,child:Wrap(children:[for(int n=1;n<=month.monthLength;n++)TextButton(onPressed:()=>Navigator.pop(ctx,Jalali(month.year,month.month,n)),child:Text(fa(n)))])),actions:[TextButton(onPressed:()=>update(()=>month=month.addMonths(-1)),child:const Text('ماه قبل')),TextButton(onPressed:()=>update(()=>month=month.addMonths(1)),child:const Text('ماه بعد'))])));if(d!=null)setState(()=>day=d);}
 Widget field(int i,String title)=>SizedBox(width:210,child:TextField(controller:fields[i],decoration:InputDecoration(labelText:title)));
 Widget menu(String value,Iterable<String> items,void Function(String) change)=>DropdownButton<String>(value:value,items:items.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)setState(()=>change(v));});
 @override Widget build(BuildContext ctx){
 final holdings=replay(rows);final latest={for(final q in quotes) q['asset']:q};
 return Scaffold(appBar:AppBar(actions:[IconButton(tooltip:'روشن / تیره',onPressed:widget.theme,icon:const Icon(Icons.brightness_6))]),body:intro?Center(child:Image.asset('assets/intro.gif',width:96)):ListView(padding:const EdgeInsets.all(24),children:[
 menu(market,markets.keys,(v){market=v;clear();}),Wrap(spacing:18,runSpacing:10,children:[field(0,'نام یا نماد'),if(['طلای فیزیکی','نقرهٔ فیزیکی'].contains(market))field(6,'عیار / خلوص'),menu(side,['خرید','فروش'],(v)=>side=v),field(1,'مقدار به ${markets[market]}'),menu(currency,['تومان','دلار'],(v)=>currency=v),field(2,'قیمت هر ${markets[market]} به $currency'),if(currency=='دلار')field(4,'نرخ دلار به تومان'),field(3,'کارمزد به تومان'),field(5,'یادداشت'),TextButton(onPressed:calendar,child:Text(display(day)))]),
 Wrap(spacing:12,children:[FilledButton(onPressed:busy?null:()=>action(()=>save(false)),child:Text(editing==null?'ثبت $side':'ذخیرهٔ تغییرات')),OutlinedButton(onPressed:busy?null:()=>action(()=>save(true)),child:const Text('ثبت قیمت واحد بالا به‌عنوان قیمت روز دستی')),TextButton(onPressed:()=>setState(clear),child:const Text('فرم تازه'))]),Text(message),const Divider(),const Text('دارایی‌ها'),for(final e in holdings.entries)Builder(builder:(_){final h=e.value,q=latest[e.key],a=jsonDecode(e.key);final value=q==null?null:h.quantity*number(q['price'])*number(q['fx']);return Card(child:ListTile(title:Text('${a.join(' ')} · موجودی ${fa(h.quantity)}'),subtitle:Text('بهای خرید ${fa(h.cost)} تومان   |   سود فروش ${fa(h.realized)} تومان\n${value==null?'قیمت روز وارد نشده':'ارزش امروز ${fa(value)} · سود موجودی ${fa(value-h.cost)} تومان · دستی'}')));}),const Divider(),const Text('تراکنش‌ها'),for(final r in rows.reversed)ListTile(title:Text('${r['side']} · ${jsonDecode(r['asset'] as String).join(' ')} · ${fa(r['qty']!)}'),subtitle:Text(display(Jalali.fromJulianDayNumber(r['day'] as int))),trailing:IconButton(icon:const Icon(Icons.edit),onPressed:()=>edit(r))) ]));
 }
}
