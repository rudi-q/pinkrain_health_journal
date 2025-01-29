import 'package:flutter/material.dart';
import 'package:pillow/util/MedicineForm.dart';
import 'package:pillow/util/MedicineList.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://lsfmimycwngjznyoavtp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzZm1pbXljd25nanpueW9hdnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU2MDY0MTksImV4cCI6MjA0MTE4MjQxOX0.ohkv_scjaWzVDwZZ4xY56ZVBuFj3tq3Nqf3w-YTmm3A',
  );



  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {


    //Get a reference your Supabase client
    final supabase = Supabase.instance.client;

    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Remove the debug mode banner
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', client: supabase),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title, required this.client});

  final String title;
  final SupabaseClient client;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pillow'),
      ),

      body: Column(
        children: [
          Expanded(child: MedicineListWidget(client: client)),  // Display the list of medicines
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddMedicineDialog(context, client);
        },
        tooltip: 'Add Medicine',
        child: const Icon(Icons.add),
      ),
    );
  }

  void showAddMedicineDialog(BuildContext context, SupabaseClient client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Medicine'),
          content: MedicineForm(client: client),
        );
      },
    );
  }

}
