import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

String _requestKey() {
  final random=Random.secure();
  final bytes=List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6]=(bytes[6]&15)|64; bytes[8]=(bytes[8]&63)|128;
  final hex=bytes.map((b)=>b.toRadixString(16).padLeft(2,'0')).join();
  return '${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
}

class CareScreen extends StatefulWidget {
  final bool professional;
  const CareScreen({super.key,this.professional=false});
  @override
  State<CareScreen> createState()=>_CareScreenState();
}
class _CareScreenState extends State<CareScreen> {
  final _api=ApiClient();
  final _search=TextEditingController();
  late Future<List<List<Map<String,dynamic>>>> _data;
  @override
  void initState(){super.initState();_reload();}
  @override
  void dispose(){_search.dispose();super.dispose();}
  void _reload(){
    _data=Future.wait([
      _api.getList('/care/services/?${widget.professional ? 'mine=true&' : ''}search=${Uri.encodeQueryComponent(_search.text)}'),
      _api.getList('/care/bookings/${widget.professional ? '?context=professional' : ''}'),
      _api.getList(widget.professional ? '/care/campaigns/?mine=true' : '/care/referrals/'),
    ]);
  }
  void _refresh()=>setState(_reload);
  void _error(Object e){if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  Future<void> _action(Map<String,dynamic> booking,String action) async {
    try{await _api.postData('/care/bookings/${booking['id']}/action/',{'action':action});if(mounted)_refresh();}catch(e){_error(e);}
  }
  Future<void> _review(Map<String,dynamic> booking) async {
    int rating=5;final comment=TextEditingController();
    final submit=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,change)=>AlertDialog(title:const Text('Rate your completed service'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButton<int>(value:rating,items:[1,2,3,4,5].map((n)=>DropdownMenuItem(value:n,child:Text('$n stars'))).toList(),onChanged:(n)=>change(()=>rating=n!)),TextField(controller:comment,maxLength:2000,decoration:const InputDecoration(labelText:'Your experience'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Submit'))])));
    if(submit==true){try{await _api.postData('/care/bookings/${booking['id']}/review/',{'rating':rating,'comment':comment.text});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Feedback submitted for moderation.')));}catch(e){_error(e);}}
    comment.dispose();
  }
  Future<void> _book(Map<String,dynamic> service,{String? referral}) async {
    final result=await Navigator.of(context).push<bool>(MaterialPageRoute(builder:(_)=>BookingScreen(service:service,referral:referral)));
    if(result==true&&mounted)_refresh();
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.professional?'Services and bookings':'Find care and book'),actions:[IconButton(onPressed:_refresh,icon:const Icon(Icons.refresh),tooltip:'Refresh')]),
    body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:960),child:FutureBuilder<List<List<Map<String,dynamic>>>>(future:_data,builder:(context,snapshot){
      if(snapshot.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('Unable to load: ${snapshot.error}'),TextButton(onPressed:_refresh,child:const Text('Retry'))]));
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final services=snapshot.data![0],bookings=snapshot.data![1],extras=snapshot.data![2];
      return ListView(padding:const EdgeInsets.all(20),children:[
        TextField(controller:_search,decoration:InputDecoration(labelText:'Search service, provider or specialty',suffixIcon:IconButton(onPressed:_refresh,icon:const Icon(Icons.search))),onSubmitted:(_)=>_refresh()),
        const SizedBox(height:16),
        if(widget.professional) FilledButton.icon(onPressed:()async{await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const ManageCareScreen()));if(mounted)_refresh();},icon:const Icon(Icons.add),label:const Text('Configure services, slots and offers')),
        const Text('Services',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        if(services.isEmpty)const Padding(padding:EdgeInsets.all(16),child:Text('No matching services available.')),
        ...services.map((s)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s['name'],style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text('${s['provider_name']} · ${s['specialty']}\n${s['location']}'),Text('INR ${s['price']} · ${s['kind']}'),Text(s['review_count']==0?'No verified ratings yet':'${s['rating']} / 5 (${s['review_count']} verified reviews)'),if((s['description'] as String).isNotEmpty)Text(s['description']),if(!widget.professional)FilledButton(onPressed:()=>_book(s),child:Text(s['kind']=='test'?'Book test':'Book appointment')),if(widget.professional)Text('Service ID ${s['id']} · ${s['active'] ? 'Active' : 'Draft'}')])))),
        if(extras.isNotEmpty)...[Text(widget.professional?'Your campaigns':'Services referred to you',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),...extras.map((e)=>Card(child:ListTile(title:Text(widget.professional?e['code']:e['service']['name']),subtitle:Text(widget.professional?'${e['reserved']} / ${e['total_limit']} reserved or redeemed\n${e['terms']}':e['note']),trailing:widget.professional?null:TextButton(onPressed:()=>_book(Map<String,dynamic>.from(e['service']),referral:e['id']),child:const Text('Book')))))],
        const SizedBox(height:16),const Text('Bookings',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        if(bookings.isEmpty)const Text('No bookings yet.'),
        ...bookings.map((b)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(b['service']['name'],style:const TextStyle(fontSize:18)),Text('${DateTime.parse(b['starts_at']).toLocal()} · ${b['status']}'),if(widget.professional)Text(b['patient_name']),Text('Original INR ${b['original_price']} − discount INR ${b['discount']} = INR ${b['payable']}'),SelectableText('Booking reference: ${b['id']}'),Wrap(spacing:12,children:[if(b['status']=='confirmed')TextButton(onPressed:()=>_action(b,'cancel'),child:const Text('Cancel booking')),if(widget.professional&&b['status']=='confirmed'&&DateTime.parse(b['starts_at']).isBefore(DateTime.now()))TextButton(onPressed:()=>_action(b,'complete'),child:const Text('Mark service completed')),if(!widget.professional&&b['status']=='completed')TextButton(onPressed:()=>_review(b),child:const Text('Leave feedback'))])])))),
      ]);
    }))),
  );
}

class BookingScreen extends StatefulWidget {
  final Map<String,dynamic> service;final String? referral;
  const BookingScreen({super.key,required this.service,this.referral});
  @override
  State<BookingScreen> createState()=>_BookingScreenState();
}
class _BookingScreenState extends State<BookingScreen>{
  final _promo=TextEditingController();final _key=_requestKey();
  late Future<List<List<Map<String,dynamic>>>> _data;
  int? _slot;Map<String,dynamic>? _quote;String? _error;bool _busy=false;
  @override
  void initState(){super.initState();_data=Future.wait([ApiClient().getList('/care/slots/?service=${widget.service['id']}'),ApiClient().getList('/care/campaigns/?service=${widget.service['id']}')]);}
  @override
  void dispose(){_promo.dispose();super.dispose();}
  Future<void> _submit(bool confirm)async{
    setState((){_busy=true;_error=null;});
    try{
      final result=await ApiClient().postData(confirm?'/care/bookings/':'/care/quote/',{'slot':_slot,'promo_code':_promo.text.trim(),'referral':widget.referral,'request_key':_key});
      if(!mounted)return;
      if(confirm){Navigator.pop(context,true);}else{setState(()=>_quote=result);}
    }catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.service['name'])),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:640),child:FutureBuilder<List<List<Map<String,dynamic>>>>(future:_data,builder:(context,snapshot){
    if(snapshot.hasError)return Text('Unable to load availability: ${snapshot.error}');
    if(!snapshot.hasData)return const CircularProgressIndicator();
    final slots=snapshot.data![0],offers=snapshot.data![1];
    return ListView(padding:const EdgeInsets.all(20),children:[Text('${widget.service['provider_name']} · ${widget.service['location']}'),const SizedBox(height:20),if(slots.isEmpty)const Text('No available slots. Please check back later.'),DropdownButtonFormField<int>(initialValue:_slot,isExpanded:true,decoration:const InputDecoration(labelText:'Available time'),items:slots.map((s)=>DropdownMenuItem<int>(value:s['id'],child:Text('${DateTime.parse(s['starts_at']).toLocal()}'))).toList(),onChanged:_busy?null:(v)=>setState((){_slot=v;_quote=null;})),
      const SizedBox(height:16),TextField(controller:_promo,enabled:!_busy,decoration:const InputDecoration(labelText:'Optional promo code'),onChanged:(_)=>setState(()=>_quote=null)),
      ...offers.map((o)=>Card(child:ListTile(title:Text('${o['code']} · ${o['kind']=='free'?'Free service':'${o['value']}${o['kind']=='percent'?'%':' INR'} discount'}'),subtitle:Text('${o['terms']}\n${o['requires_referral']?'Valid referral required. ':''}Expires ${DateTime.parse(o['ends_at']).toLocal()}'),onTap:_busy?null:()=>setState((){_promo.text=o['code'];_quote=null;})))),
      if(_quote!=null)...[const Divider(),Text('Original price: INR ${_quote!['original_price']}\nDiscount: INR ${_quote!['discount']}\nTotal payable: INR ${_quote!['payable']}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(_quote!['terms']),const Text('Availability is reserved only when your booking is confirmed.')],
      if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),const SizedBox(height:16),FilledButton(onPressed:_busy||_slot==null?null:()=>_submit(_quote!=null),child:Text(_busy?'Please wait…':_quote==null?'Review final price':'Confirm booking')),
    ]);
  }))));
}

class ManageCareScreen extends StatefulWidget{
  const ManageCareScreen({super.key});
  @override State<ManageCareScreen> createState()=>_ManageCareScreenState();
}
class _ManageCareScreenState extends State<ManageCareScreen>{
  String _type='service';bool _busy=false,_approved=false,_referralRequired=false;String? _message;
  final Map<String,TextEditingController> _fields={};
  TextEditingController _field(String name)=>_fields.putIfAbsent(name,()=>TextEditingController());
  @override void dispose(){for(final c in _fields.values){c.dispose();}super.dispose();}
  Future<void> _save()async{
    setState((){_busy=true;_message=null;});
    try{
      String value(String key)=>_field(key).text.trim();
      Map<String,dynamic> data;
      if(_type=='service'){
        data={'name':value('Name'),'kind':value('Kind'),'specialty':value('Specialty'),'location':value('Location'),'price':value('Price'),'description':value('Description'),'active':true};
      }else if(_type=='slot'){
        data={'service':int.parse(value('Service ID')),'starts_at':DateTime.parse(value('Start (YYYY-MM-DD HH:MM)')).toUtc().toIso8601String(),'capacity':int.parse(value('Capacity'))};
      }else{
        data={'service':int.parse(value('Service ID')),'code':value('Promo code'),'kind':value('Discount kind'),'value':value('Discount value').isEmpty?'0':value('Discount value'),'total_limit':int.parse(value('Total limit')),'per_patient_limit':int.parse(value('Per patient limit')),'starts_at':DateTime.parse(value('Start (YYYY-MM-DD HH:MM)')).toUtc().toIso8601String(),'ends_at':DateTime.parse(value('End (YYYY-MM-DD HH:MM)')).toUtc().toIso8601String(),'funded_by':value('Funded by'),'terms':value('Offer terms'),'partner_approved':_approved,'active':_approved,'requires_referral':_referralRequired,'max_discount':value('Maximum discount').isEmpty?null:value('Maximum discount')};
      }
      final result=await ApiClient().postData('/care/${_type=='service'?'services':_type=='slot'?'slots':'campaigns'}/',data);
      if(mounted)setState(()=>_message='Saved successfully. Reference ${result['id']}');
    }catch(e){if(mounted)setState(()=>_message='Not saved: $e');}finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context){
    final names=_type=='service'?['Name','Kind','Specialty','Location','Price','Description']:_type=='slot'?['Service ID','Start (YYYY-MM-DD HH:MM)','Capacity']:['Service ID','Promo code','Discount kind','Discount value','Maximum discount','Total limit','Per patient limit','Start (YYYY-MM-DD HH:MM)','End (YYYY-MM-DD HH:MM)','Funded by','Offer terms'];
    return Scaffold(appBar:AppBar(title:const Text('Configure booking')),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:640),child:ListView(padding:const EdgeInsets.all(20),children:[DropdownButton<String>(value:_type,items:['service','slot','campaign'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:_busy?null:(v)=>setState((){_type=v!;_message=null;})),const Text('Service kinds: consultation, test, hospital. Discount kinds: percent, fixed, free. Times use your local timezone. Prices include all mandatory charges.'),...names.map((name)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:TextField(controller:_field(name),enabled:!_busy,decoration:InputDecoration(labelText:name)))),if(_type=='campaign')CheckboxListTile(value:_referralRequired,onChanged:_busy?null:(v)=>setState(()=>_referralRequired=v!),title:const Text('Require an unexpired referral for this service')),if(_type=='campaign')CheckboxListTile(value:_approved,onChanged:_busy?null:(v)=>setState(()=>_approved=v!),title:const Text('Our organization approves and funds this offer under the stated terms. A free offer includes all mandatory charges.')),if(_message!=null)Text(_message!),FilledButton(onPressed:_busy?null:_save,child:Text(_busy?'Saving…':'Save'))]))));
  }
}
