import 'package:flutter/material.dart';
class HospitalIntegrationStatusScreen extends StatelessWidget {
  const HospitalIntegrationStatusScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Hospital integration status')),body:const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No external hospital system is configured. Use the secure manual upload workflow. Automatic synchronization and external system health have not been verified.'))));
}
