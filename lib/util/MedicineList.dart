import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineListWidget extends StatefulWidget {

  final SupabaseClient client;

  const MedicineListWidget({super.key, required this.client});

  @override
  _MedicineListState createState() => _MedicineListState();

}
class _MedicineListState extends State<MedicineListWidget> {

void refreshList(){
  setState(() {});
}

Future<List<Map<String, dynamic>>> _fetchMedicines() async {
    final data = await widget.client
        .from('medications')
        .select();

    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMedicines(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No medicines found'));
        } else {
          final medicines = snapshot.data!;
          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 12),
                elevation: 4.0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(medicine['medication_name'] ?? 'No Name'),
                  subtitle: Text(
                    'Dosage: ${medicine['dosage'] ?? 'N/A'}, '
                        'Frequency: ${medicine['frequency_per_day'] ?? 'N/A'}, '
                        'Start Date: ${medicine['start_date'] ?? 'N/A'}, '
                        'End Date: ${medicine['end_date'] ?? 'N/A'}',
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
