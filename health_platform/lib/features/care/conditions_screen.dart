import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key});
  @override State<ConditionsScreen> createState()=>_ConditionsScreenState();
}
class _ConditionsScreenState extends State<ConditionsScreen>{
  static const options=['Diabetes (high blood sugar)','High blood pressure','Asthma (breathing difficulty)','Thyroid condition','Heart condition','Kidney condition','Other',"I don't know"];
  final _other=TextEditingController();final Set<String> _selected={};
  bool _loading=true,_saving=false;String? _error;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_other.dispose();super.dispose();}
  Future<void> _load()async{
    try{final data=await ApiClient().getData('/patients/me/');if(!mounted)return;setState((){_selected.addAll((data['medical_conditions'] as List? ?? []).map((v)=>v.toString()));_loading=false;});}
    catch(e){if(mounted)setState((){_error=e.toString();_loading=false;});}
  }
  Future<void> _save()async{
    setState((){_saving=true;_error=null;});
    try{
      final values=_selected.where((s)=>s!='Other').toList();
      if(_selected.contains('Other')){if(_other.text.trim().isEmpty)throw Exception('Describe the other condition, or choose I don’t know.');values.add(_other.text.trim());}
      await ApiClient().patchData('/patients/me/',{'medical_conditions':values});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your health information was saved.')));Navigator.pop(context);}
    }catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Health conditions')),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:640),child:_loading?const CircularProgressIndicator():ListView(padding:const EdgeInsets.all(20),children:[const Text('Choose conditions you have been told you have. If you are unsure, choose “I don’t know”. These are your answers, not a diagnosis.'),const SizedBox(height:16),DropdownButtonFormField<String>(decoration:const InputDecoration(labelText:'Add a condition'),isExpanded:true,items:options.map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),onChanged:_saving?null:(s)=>setState(()=>_selected.add(s!))),Wrap(spacing:8,children:_selected.map((s)=>InputChip(label:Text(s),onDeleted:_saving?null:()=>setState(()=>_selected.remove(s)))).toList()),if(_selected.contains('Other'))TextField(controller:_other,maxLength:200,decoration:const InputDecoration(labelText:'Other condition')),if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),FilledButton(onPressed:_saving?null:_save,child:Text(_saving?'Saving…':'Save health conditions'))]))));
}
