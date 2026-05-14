//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//Bukamuso Shudufhadzo Luvhengo 224015143
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/application.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      // Redirect if student tries to access admin dashboard
      if (authViewModel.userRole == 'student') {
        Navigator.pushReplacementNamed(context, '/student-home');
        return;
      }
      // Load applications
      final viewModel = Provider.of<AdminDashboardViewModel>(context, listen: false);
      viewModel.loadApplications();
    });
  }

  Future<void> _launchDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }

  Future<void> _updateStatus(AdminDashboardViewModel viewModel, String id, String status) async {
    final success = await viewModel.updateStatus(id, status);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $status'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showReviewDialog(AdminDashboardViewModel viewModel, Application application) async {
    String selectedStatus = application.status;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${application.studentName ?? "Unknown"}', 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Student Number: ${application.studentNumber ?? "N/A"}'),
                    Text('Email: ${application.studentEmail ?? "N/A"}'),
                    Text('Year of Study: Year ${application.yearOfStudy}'),
                    Text('Submitted: ${_formatDate(application.submittedAt)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Applied Modules:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...application.modules.map((module) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      module.meetsRequirements ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: module.meetsRequirements ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(module.moduleName)),
                    Text('Year ${module.academicLevel}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
              if (application.additionalNotes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const Text('Additional Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(application.additionalNotes!),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Decision:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'approved', label: Text('Approve'), icon: Icon(Icons.check_circle)),
                  ButtonSegment(value: 'rejected', label: Text('Reject'), icon: Icon(Icons.cancel)),
                  ButtonSegment(value: 'pending', label: Text('Pending'), icon: Icon(Icons.hourglass_empty)),
                ],
                selected: {selectedStatus},
                onSelectionChanged: (Set<String> newSelection) {
                  selectedStatus = newSelection.first;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateStatus(viewModel, application.id, selectedStatus);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminDashboardViewModel viewModel, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteApplication(id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application deleted'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete application'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final viewModel = Provider.of<AdminDashboardViewModel>(context);
    
    // Extra safety check - if student, don't show admin dashboard
    if (authViewModel.userRole == 'student') {
      return const Scaffold(
        body: Center(child: Text('Students cannot access admin dashboard')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Review Applications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Admin: ${authViewModel.currentUser?.email?.split('@').first ?? 'Admin'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadApplications(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authViewModel.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Total', viewModel.totalCount.toString(), Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Pending', viewModel.pendingCount.toString(), Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Approved', viewModel.approvedCount.toString(), Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Rejected', viewModel.rejectedCount.toString(), Colors.red),
              ],
            ),
          ),
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', viewModel),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending', viewModel),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved', viewModel),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected', viewModel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Applications List
          Expanded(
            child: _buildBody(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, AdminDashboardViewModel viewModel) {
    return FilterChip(
      label: Text(label),
      selected: viewModel.selectedStatusFilter == filter,
      onSelected: (selected) {
        if (selected) {
          viewModel.setStatusFilter(filter);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
    );
  }

  Widget _buildBody(AdminDashboardViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadApplications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Applications Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('No students have submitted applications yet', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.applications.length,
      itemBuilder: (context, index) {
        final app = viewModel.applications[index];
        return _buildApplicationCard(app, viewModel);
      },
    );
  }

  Widget _buildApplicationCard(Application application, AdminDashboardViewModel viewModel) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (application.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'PENDING REVIEW';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'APPROVED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'UNKNOWN';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: application.status == 'pending' 
            ? BorderSide(color: Colors.orange.shade300, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application.studentName ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Year ${application.yearOfStudy} Student',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Text(
          'Submitted: ${_formatDate(application.submittedAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 STUDENT INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildInfoRow('Student Number', application.studentNumber ?? 'N/A'),
                      _buildInfoRow('Email', application.studentEmail ?? 'N/A'),
                      _buildInfoRow('Year of Study', 'Year ${application.yearOfStudy}'),
                      _buildInfoRow('Student ID', application.userId.substring(0, 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Modules
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📚 APPLIED MODULES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...application.modules.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final module = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Module $index:', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    module.meetsRequirements ? Icons.check_circle : Icons.warning,
                                    size: 16,
                                    color: module.meetsRequirements ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(module.moduleName)),
                                  Text('Year ${module.academicLevel}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Additional Notes
                if (application.additionalNotes != null && application.additionalNotes!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(' ADDITIONAL NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(application.additionalNotes!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Document
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(' SUPPORTING DOCUMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              'Click the button to view the uploaded document',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchDocument(application.documentUrl),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                
                // Admin Actions
                const Text(' ADMIN ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                if (application.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReviewDialog(viewModel, application),
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Review Application'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(viewModel, application.id, 'approved'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Quick Approve'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(viewModel, application.id, 'rejected'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Quick Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(viewModel, application.id),
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(viewModel, application.id, 'pending'),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reopen Review'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(viewModel, application.id),
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}