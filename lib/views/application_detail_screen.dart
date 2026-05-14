//STUDENT NUMBERS :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NAMES : 224124772, 223059218,223059218, 223059551, 224022767, 224015143

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/application.dart';
import '../viewmodels/student_home_viewmodel.dart';
import 'application_form_screen.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final Application application;
  const ApplicationDetailScreen({super.key, required this.application});

  Future<void> _launchDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))],
      ),
    );

    if (confirm == true) {
      final viewModel = Provider.of<StudentHomeViewModel>(context, listen: false);
      final success = await viewModel.deleteApplication(application.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage ?? 'Failed'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Colors.blue,
        actions: [if (application.status == 'pending') IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(color: application.status == 'pending' ? Colors.orange.shade50 : application.status == 'approved' ? Colors.green.shade50 : Colors.red.shade50, child: ListTile(title: Text('Status: ${application.status.toUpperCase()}'))),
            const SizedBox(height: 16),
            Card(child: ListTile(title: const Text('Student Information'), subtitle: Column(children: [Text('Year ${application.yearOfStudy}'), Text('Submitted: ${application.submittedAt}')]))),
            const SizedBox(height: 16),
            Card(child: ExpansionTile(title: const Text('Modules'), children: application.modules.map((m) => ListTile(title: Text(m.moduleName), subtitle: Text('Year ${m.academicLevel} - ${m.meetsRequirements ? "Meets requirements" : "Does not meet requirements"}'))).toList())),
            const SizedBox(height: 16),
            Card(child: ListTile(title: const Text('Document'), trailing: ElevatedButton(onPressed: () => _launchDocument(application.documentUrl), child: const Text('View')), subtitle: Text(application.originalFilename ?? 'Supporting document'))),
            if (application.additionalNotes != null) const SizedBox(height: 16),
            if (application.additionalNotes != null) Card(child: ListTile(title: const Text('Additional Notes'), subtitle: Text(application.additionalNotes!))),
            if (application.status == 'pending') ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ApplicationFormScreen(applicationToEdit: application))).then((_) => Navigator.pop(context)),
                child: const Text('Edit Application'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
