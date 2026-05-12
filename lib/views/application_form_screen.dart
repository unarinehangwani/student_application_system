//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/application_form_viewmodel.dart';
import '../models/application.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Application? applicationToEdit;

  const ApplicationFormScreen({super.key, this.applicationToEdit});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  int? _yearOfStudy;
  int? _firstModuleLevel;
  String? _firstModuleName;
  bool _firstModuleMeetsRequirements = false;
  bool _includeSecondModule = false;
  int? _secondModuleLevel;
  String? _secondModuleName;
  bool _secondModuleMeetsRequirements = false;
  bool _confirmEligibility = false;
  File? _documentFile;
  String? _existingDocumentUrl;
  String? _additionalNotes;

  List<Module> _modules = [];

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ApplicationFormViewModel>(
      context,
      listen: false,
    );
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
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024;

        if (fileSize > maxSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size exceeds 10MB limit'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _documentFile = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${result.files.single.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Module> _getModulesByLevel(int level) {
    return _modules.where((m) => m.academicLevel == level).toList();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_documentFile == null && _existingDocumentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload supporting document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_confirmEligibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm eligibility'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = Provider.of<ApplicationFormViewModel>(
      context,
      listen: false,
    );

    final success = await viewModel.submitApplication(
      yearOfStudy: _yearOfStudy!,
      firstModule: {
        'academic_level': _firstModuleLevel,
        'module_name': _firstModuleName,
        'meets_requirements': _firstModuleMeetsRequirements,
      },
      secondModule: _includeSecondModule && _secondModuleName != null
          ? {
              'academic_level': _secondModuleLevel,
              'module_name': _secondModuleName,
              'meets_requirements': _secondModuleMeetsRequirements,
            }
          : null,
      document: _documentFile,
      additionalNotes: _additionalNotes,
      existingDocumentUrl: _existingDocumentUrl,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.applicationToEdit != null
                  ? 'Application updated!'
                  : 'Application submitted!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Submission failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ApplicationFormViewModel>(context);
    _modules = viewModel.availableModules;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.applicationToEdit != null
              ? 'Edit Application'
              : 'New Application',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Academic Information
                    _buildSection(
                      title: 'Academic Information',
                      icon: Icons.school,
                      color: Colors.blue,
                      child: DropdownButtonFormField<int>(
                        initialValue: _yearOfStudy,
                        decoration: const InputDecoration(
                          labelText: 'Current Year of Study *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Year 1')),
                          DropdownMenuItem(value: 2, child: Text('Year 2')),
                          DropdownMenuItem(value: 3, child: Text('Year 3')),
                        ],
                        onChanged: (value) =>
                            setState(() => _yearOfStudy = value),
                        validator: (value) => value == null
                            ? 'Please select year of study'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 2: First Module
                    _buildSection(
                      title: 'First Module (Required)',
                      icon: Icons.library_books,
                      color: Colors.green,
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _firstModuleLevel,
                            decoration: const InputDecoration(
                              labelText: 'Academic Level *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Year 1')),
                              DropdownMenuItem(value: 2, child: Text('Year 2')),
                              DropdownMenuItem(value: 3, child: Text('Year 3')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _firstModuleLevel = value;
                                _firstModuleName = null;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Please select academic level'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _firstModuleName,
                            decoration: const InputDecoration(
                              labelText: 'Select Module *',
                              border: OutlineInputBorder(),
                            ),
                            items: _firstModuleLevel != null
                                ? _getModulesByLevel(_firstModuleLevel!).map((
                                    module,
                                  ) {
                                    return DropdownMenuItem(
                                      value: module.moduleName,
                                      child: Text(
                                        '${module.moduleCode} - ${module.moduleName}',
                                      ),
                                    );
                                  }).toList()
                                : [],
                            onChanged: (value) =>
                                setState(() => _firstModuleName = value),
                            validator: (value) =>
                                value == null ? 'Please select a module' : null,
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text(
                              'I meet the minimum requirements for this module',
                            ),
                            value: _firstModuleMeetsRequirements,
                            onChanged: (value) => setState(
                              () => _firstModuleMeetsRequirements = value!,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Second Module (Optional)
                    Card(
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text(
                              'Apply for a second module (Optional)',
                            ),
                            value: _includeSecondModule,
                            onChanged: (value) =>
                                setState(() => _includeSecondModule = value!),
                          ),
                          if (_includeSecondModule)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<int>(
                                    initialValue: _secondModuleLevel,
                                    decoration: const InputDecoration(
                                      labelText: 'Academic Level',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('Year 1'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('Year 2'),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Text('Year 3'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _secondModuleLevel = value;
                                        _secondModuleName = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _secondModuleName,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Module',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _secondModuleLevel != null
                                        ? _getModulesByLevel(
                                            _secondModuleLevel!,
                                          ).map((module) {
                                            return DropdownMenuItem(
                                              value: module.moduleName,
                                              child: Text(
                                                '${module.moduleCode} - ${module.moduleName}',
                                              ),
                                            );
                                          }).toList()
                                        : [],
                                    onChanged: (value) => setState(
                                      () => _secondModuleName = value,
                                    ),
                                    validator: (value) {
                                      if (_includeSecondModule &&
                                          value == null) {
                                        return 'Please select a module';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CheckboxListTile(
                                    title: const Text(
                                      'I meet the minimum requirements for this module',
                                    ),
                                    value: _secondModuleMeetsRequirements,
                                    onChanged: (value) => setState(
                                      () => _secondModuleMeetsRequirements =
                                          value!,
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 4: Supporting Documents
                    _buildSection(
                      title: 'Supporting Documents',
                      icon: Icons.attach_file,
                      color: Colors.orange,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _documentFile != null
                                      ? 'New file: ${_documentFile!.path.split('/').last}'
                                      : (_existingDocumentUrl != null
                                            ? 'Current document uploaded'
                                            : 'No file selected'),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickDocument,
                                icon: const Icon(Icons.upload),
                                label: Text(
                                  _documentFile != null
                                      ? 'Change File'
                                      : 'Upload',
                                ),
                              ),
                            ],
                          ),
                          if (_existingDocumentUrl != null &&
                              _documentFile == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Keeping existing document. Upload new file to replace.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 5: Additional Notes
                    _buildSection(
                      title: 'Additional Notes (Optional)',
                      icon: Icons.note,
                      color: Colors.purple,
                      child: TextFormField(
                        initialValue: _additionalNotes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Any additional information you want to provide...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _additionalNotes = value,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 6: Confirmation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'I confirm that all information provided is accurate and I understand that eligibility decisions are made by administrative staff',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        value: _confirmEligibility,
                        onChanged: (value) =>
                            setState(() => _confirmEligibility = value!),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.applicationToEdit != null
                              ? 'Update Application'
                              : 'Submit Application',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
