//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143
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
      Provider.of<AdminDashboardViewModel>(context, listen: false).loadApplications();
    });
  }

  Future<void> _handleStatusChange(Application application, String newStatus) async {
    final viewModel = Provider.of<AdminDashboardViewModel>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus.toUpperCase()} Application'),
        content: Text('Are you sure you want to ${newStatus.toLowerCase()} this application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(newStatus.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.updateStatus(application.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Application ${newStatus}d' : 'Update failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteApplication(Application application) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final viewModel = Provider.of<AdminDashboardViewModel>(context, listen: false);
      final success = await viewModel.deleteApplication(application.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Application deleted' : 'Delete failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final viewModel = Provider.of<AdminDashboardViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authViewModel.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsRow(viewModel),
          
          // Filter Tabs
          _buildFilterTabs(viewModel),
          
          // Applications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => viewModel.loadApplications(),
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.applications.isEmpty
                      ? const Center(child: Text('No applications found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: viewModel.applications.length,
                          itemBuilder: (context, index) {
                            return _buildApplicationCard(viewModel.applications[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AdminDashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', viewModel.totalCount, Colors.blue),
          _buildStatCard('Pending', viewModel.pendingCount, Colors.orange),
          _buildStatCard('Approved', viewModel.approvedCount, Colors.green),
          _buildStatCard('Rejected', viewModel.rejectedCount, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AdminDashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', viewModel),
          _buildFilterChip('Pending', 'pending', viewModel),
          _buildFilterChip('Approved', 'approved', viewModel),
          _buildFilterChip('Rejected', 'rejected', viewModel),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, AdminDashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: viewModel.selectedStatusFilter == value,
        onSelected: (_) => viewModel.setStatusFilter(value),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
      ),
    );
  }

  Widget _buildApplicationCard(Application application) {
    Color statusColor;
    IconData statusIcon;
    
    switch (application.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${application.studentNumber ?? 'No Number'} • Year ${application.yearOfStudy}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Wrap(
          spacing: 8,
          children: application.modules.map((module) {
            return Chip(
              label: Text(module.moduleName),
              backgroundColor: Colors.blue.shade50,
              labelStyle: const TextStyle(fontSize: 10),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            application.status.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildDetailRow('Student Email', application.studentEmail ?? 'N/A'),
                _buildDetailRow('Student Number', application.studentNumber ?? 'N/A'),
                _buildDetailRow('Year of Study', 'Year ${application.yearOfStudy}'),
                _buildDetailRow('Submitted', _formatDate(application.submittedAt)),
                _buildDetailRow('Last Updated', _formatDate(application.updatedAt)),
                const SizedBox(height: 12),
                const Text('Modules Applied:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...application.modules.map((module) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${module.moduleName} (Year ${module.academicLevel}) - ${module.meetsRequirements ? "Meets requirements" : "Does not meet requirements"}'),
                )),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _viewDocument(application.documentUrl),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, size: 16),
                        const SizedBox(width: 8),
                        const Text('View Supporting Document'),
                        const Spacer(),
                        const Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ),
                if (application.additionalNotes?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  const Text('Additional Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(application.additionalNotes!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (application.status == 'pending') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleStatusChange(application, 'approved'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleStatusChange(application, 'rejected'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteApplication(application),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteApplication(application),
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}