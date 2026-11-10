import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:png_transfer_flutter_core/png_transfer_flutter_core.dart';
void main(){
 testWidgets('DISPATCHER mobile login has correct account actions',(tester)async{
 await tester.pumpWidget(MaterialApp(home:DemoLoginPanel(role:'DISPATCHER',onLogin:(e,p)async{},onRegister:(n,e,p,ph)async{})));
 expect(find.text('AeroTrans ${roleName('DISPATCHER')}'),findsOneWidget);
 expect(find.text('Create a customer account'),findsNothing);
 expect(find.textContaining('ISOLATED DEMO'),findsOneWidget);
 });
 testWidgets('unavailable local services remain visible',(tester)async{
 await tester.pumpWidget(const LocalFoundationApp(role:'DISPATCHER',error:'Connect the demo phone by USB'));
 expect(find.text('Local setup needs attention.'),findsOneWidget);
 expect(find.text('Connect the demo phone by USB'),findsOneWidget);
 });
}
