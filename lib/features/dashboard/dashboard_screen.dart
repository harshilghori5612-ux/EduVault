import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/student_model.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/student_card.dart';
import '../students/student_provider.dart';
import '../documents/document_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalStudents = 0;
  int _totalDocuments = 0;
  int _pendingDocStudents = 0;
  List<StudentModel> _recentStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final totalSt = await db.getTotalStudents();
    final totalDoc = await db.getTotalDocuments();
    final pendingSt = await db.getStudentsWithPendingDocumentsCount();
    final recents = await db.getRecentlyAddedStudents(limit: 5);

    if (mounted) {
      setState(() {
        _totalStudents = totalSt;
        _totalDocuments = totalDoc;
        _pendingDocStudents = pendingSt;
        _recentStudents = recents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              _loadDashboardData();
              Provider.of<StudentProvider>(context, listen: false).loadStudents();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Text(
                      'Welcome, Admin',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is an overview of student records & documents.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.25,
                      children: [
                        StatCard(
                          title: 'Total Students',
                          value: '$_totalStudents',
                          icon: Icons.people_alt_rounded,
                          color: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.studentList);
                          },
                        ),
                        StatCard(
                          title: 'Total Documents',
                          value: '$_totalDocuments',
                          icon: Icons.description_rounded,
                          color: theme.colorScheme.secondary,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.documentList);
                          },
                        ),
                        StatCard(
                          title: 'Pending Docs',
                          value: '$_pendingDocStudents',
                          icon: Icons.pending_actions_rounded,
                          color: theme.colorScheme.tertiary,
                        ),
                        StatCard(
                          title: 'Completion Rate',
                          value: _totalStudents > 0
                              ? '${(((_totalStudents - _pendingDocStudents) / _totalStudents) * 100).toInt()}%'
                              : '100%',
                          icon: Icons.verified_rounded,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ActionTileButton(
                            icon: Icons.person_add_rounded,
                            label: 'Add Student',
                            color: theme.colorScheme.primary,
                            onTap: () async {
                              await Navigator.pushNamed(context, Routes.addStudent);
                              _loadDashboardData();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ActionTileButton(
                            icon: Icons.view_list_rounded,
                            label: 'View Students',
                            color: theme.colorScheme.secondary,
                            onTap: () {
                              Navigator.pushNamed(context, Routes.studentList);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ActionTileButton(
                            icon: Icons.document_scanner_rounded,
                            label: 'Scan Doc',
                            color: theme.colorScheme.tertiary,
                            onTap: () async {
                              await Navigator.pushNamed(context, Routes.documentScanner);
                              _loadDashboardData();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Recently Added Students
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recently Added Students',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, Routes.studentList);
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _recentStudents.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 40,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No students added yet',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentStudents.length,
                            itemBuilder: (context, index) {
                              final student = _recentStudents[index];
                              return StudentCard(
                                student: student,
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    Routes.studentProfile,
                                    arguments: student.id,
                                  );
                                  _loadDashboardData();
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ActionTileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionTileButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
