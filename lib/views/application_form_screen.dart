//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/application_form_viewmodel.dart';
import '../models/application.dart';
import '../viewmodels/auth_viewmodel.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Application? applicationToEdit;
  const ApplicationFormScreen({super.key, this.applicationToEdit});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _yearOfStudy;
  int? _firstModuleLevel;
  String? _firstModuleName;
  bool _firstModuleMeetsRequirements = false;
  bool _includeSecondModule = false;
  int? _secondModuleLevel;
  String? _secondModuleName;
  bool _secondModuleMeetsRequirements = false;
  bool _confirmEligibility = false;
  String? _additionalNotes;
  File? _mobileFile;
  Uint8List? _webFileBytes;
  String? _webFileName;
  String? _existingDocumentUrl;
  bool _hasFile = false;
  List<Module> _modules = [];

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ApplicationFormViewModel>(context, listen: false);
    viewModel.loadModules();

    if (widget.applicationToEdit != null) {
      viewModel.setEditingMode(widget.applicationToEdit!.id);
      _loadApplicationForEdit();
    }
  }

  void _loadApplicationForEdit() {
    final app = widget.applicationToEdit!;
    _yearOfStudy = app.yearOfStudy;
    _existingDocumentUrl = app.documentUrl;
    _additionalNotes = app.additionalNotes;

    if (app.modules.isNotEmpty) {
      _firstModuleLevel = app.modules[0].academicLevel;
      _firstModuleName = app.modules[0].moduleName;
      _firstModuleMeetsRequirements = app.modules[0].meetsRequirements;
    }

    if (app.modules.length > 1) {
      _includeSecondModule = true;
      _secondModuleLevel = app.modules[1].academicLevel;
      _secondModuleName = app.modules[1].moduleName;
      _secondModuleMeetsRequirements = app.modules[1].meetsRequirements;
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        const maxSize = 10 * 1024 * 1024;
        if (file.size > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File size exceeds 10MB'), backgroundColor: Colors.red));
          return;
        }

        setState(() => _hasFile = true);

        if (kIsWeb) {
          _webFileBytes = file.bytes;
          _webFileName = file.name;
          _mobileFile = null;
        } else if (file.path != null) {
          _mobileFile = File(file.path!);
          _webFileBytes = null;
          _webFileName = file.name;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: ${file.name}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  List<Module> _getModulesByLevel(int level) {
    return _modules.where((m) => m.academicLevel == level).toList();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    bool hasFile = kIsWeb ? _webFileBytes != null : _mobileFile != null;
    if (!hasFile && _existingDocumentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload document'), backgroundColor: Colors.red));
      return;
    }
    if (!_confirmEligibility) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirm eligibility'), backgroundColor: Colors.red));
      return;
    }

    final viewModel = Provider.of<ApplicationFormViewModel>(context, listen: false);
    final success = await viewModel.submitApplication(
      yearOfStudy: _yearOfStudy!,
      firstModule: {'academic_level': _firstModuleLevel, 'module_name': _firstModuleName, 'meets_requirements': _firstModuleMeetsRequirements},
      secondModule: _includeSecondModule && _secondModuleName != null ? {'academic_level': _secondModuleLevel, 'module_name': _secondModuleName, 'meets_requirements': _secondModuleMeetsRequirements} : null,
      mobileFile: _mobileFile,
      webFileBytes: _webFileBytes,
      webFileName: _webFileName,
      additionalNotes: _additionalNotes,
      existingDocumentUrl: _existingDocumentUrl,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage ?? 'Failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    if (authViewModel.userRole == 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied'), backgroundColor: Colors.red),
        body: const Center(child: Text('Admins cannot submit applications')),
      );
    }

    final viewModel = Provider.of<ApplicationFormViewModel>(context);
    _modules = viewModel.availableModules;

    return Scaffold(
      appBar: AppBar(title: Text(widget.applicationToEdit != null ? 'Edit Application' : 'New Application'), backgroundColor: Colors.blue),
      body: viewModel.isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _yearOfStudy,
                decoration: const InputDecoration(labelText: 'Year of Study *'),
                items: const [DropdownMenuItem(value: 1, child: Text('Year 1')), DropdownMenuItem(value: 2, child: Text('Year 2')), DropdownMenuItem(value: 3, child: Text('Year 3'))],
                onChanged: (value) => setState(() => _yearOfStudy = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _firstModuleLevel,
                decoration: const InputDecoration(labelText: 'First Module Level *'),
                items: const [DropdownMenuItem(value: 1, child: Text('Year 1')), DropdownMenuItem(value: 2, child: Text('Year 2')), DropdownMenuItem(value: 3, child: Text('Year 3'))],
                onChanged: (value) => setState(() => _firstModuleLevel = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _firstModuleName,
                decoration: const InputDecoration(labelText: 'First Module *'),
                items: _firstModuleLevel != null ? _getModulesByLevel(_firstModuleLevel!).map((m) => DropdownMenuItem(value: m.moduleName, child: Text(m.moduleName))).toList() : [],
                onChanged: (value) => setState(() => _firstModuleName = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              CheckboxListTile(title: const Text('Meet requirements'), value: _firstModuleMeetsRequirements, onChanged: (v) => setState(() => _firstModuleMeetsRequirements = v!)),
              CheckboxListTile(title: const Text('Apply for second module'), value: _includeSecondModule, onChanged: (v) => setState(() => _includeSecondModule = v!)),
              if (_includeSecondModule) ...[
                DropdownButtonFormField<int>(
                  value: _secondModuleLevel,
                  decoration: const InputDecoration(labelText: 'Second Module Level'),
                  items: const [DropdownMenuItem(value: 1, child: Text('Year 1')), DropdownMenuItem(value: 2, child: Text('Year 2')), DropdownMenuItem(value: 3, child: Text('Year 3'))],
                  onChanged: (value) => setState(() => _secondModuleLevel = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _secondModuleName,
                  decoration: const InputDecoration(labelText: 'Second Module'),
                  items: _secondModuleLevel != null ? _getModulesByLevel(_secondModuleLevel!).map((m) => DropdownMenuItem(value: m.moduleName, child: Text(m.moduleName))).toList() : [],
                  onChanged: (value) => setState(() => _secondModuleName = value),
                ),
                CheckboxListTile(title: const Text('Meet requirements'), value: _secondModuleMeetsRequirements, onChanged: (v) => setState(() => _secondModuleMeetsRequirements = v!)),
              ],
              const SizedBox(height: 20),
              Row(children: [Expanded(child: Text(_hasFile ? _webFileName ?? 'File selected' : 'No file')), ElevatedButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.upload), label: const Text('Upload'))]),
              const SizedBox(height: 20),
              TextFormField(maxLines: 3, decoration: const InputDecoration(labelText: 'Additional Notes'), onChanged: (v) => _additionalNotes = v),
              const SizedBox(height: 20),
              CheckboxListTile(title: const Text('I confirm eligibility'), value: _confirmEligibility, onChanged: (v) => setState(() => _confirmEligibility = v!)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _submitForm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Submit Application')),
            ],
          ),
        ),
      ),
    );
  }
}