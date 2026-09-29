import 'package:flutter/material.dart';
class LabIntegrationStatusScreen extends StatelessWidget {
  const LabIntegrationStatusScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Lab integration status')),body:const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No external lab system is configured. Use the secure manual upload workflow. Automatic synchronization and external system health have not been verified.'))));
}
