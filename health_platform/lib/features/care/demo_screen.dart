import 'package:flutter/material.dart';
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override State<DemoScreen> createState()=>_DemoScreenState();
}
class _DemoScreenState extends State<DemoScreen>{
  int _step=0;bool _professional=false;
  @override Widget build(BuildContext context){
    final steps=_professional?const [
      ['Verify your organization','Register the professional role and credentials. An administrator must approve clinical access before you can use the web portal.'],
      ['Ask for patient consent','Find the exact patient account and request consent. Only the patient can approve access, and consent expires.'],
      ['Publish actual clinical information','Use measured results and the correct patient. Attach an actual report or discharge document. Patients receive a notification.'],
      ['Configure bookings and real offers','Create a service with its complete price, future slots, and capacity. Add a campaign only when your organization has agreed to fund its published terms.'],
      ['Complete the service','Find the confirmed booking reference. Mark completion after providing the service. The patient can then submit feedback.'],
    ]:const [
      ['Sign in with your email','Enter the verification code delivered to your inbox. Each email has one account.'],
      ['Add your health information','Choose known conditions or “I don’t know”. Upload historical PDF, Word or photo reports with their original date.'],
      ['Control access','Review consent requests in your dashboard. You decide which reviewed professionals may access your medical records.'],
      ['Find care and book','Choose a service and available slot, apply an eligible promo code, then review the total price. A free offer shows INR 0.00 with all mandatory charges included.'],
      ['Follow your care','Use bookings and notifications for updates. Open records and reports securely. After a completed service, leave feedback for moderation.'],
    ];
    return Scaffold(appBar:AppBar(title:const Text('Guided walkthrough')),body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:800),child:Column(children:[const Padding(padding:EdgeInsets.all(16),child:Text('Walkthrough only. No patient records, bookings or offers are created.')),SwitchListTile(title:const Text('Show professional web workflow'),value:_professional,onChanged:(v)=>setState((){_professional=v;_step=0;})),Expanded(child:Stepper(currentStep:_step,onStepTapped:(n)=>setState(()=>_step=n),onStepContinue:_step<steps.length-1?()=>setState(()=>_step++):null,onStepCancel:_step>0?()=>setState(()=>_step--):null,steps:steps.map((s)=>Step(title:Text(s[0]),content:Text(s[1]),isActive:steps.indexOf(s)<=_step)).toList()))]))));
  }
}
