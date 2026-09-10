import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/document_categories.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/widgets/document_card.dart';
import 'document_provider.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentProvider>(context, listen: false).loadAllDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final allDocs = docProvider.allDocuments;

    // Apply Filter & Search
    final filteredDocs = allDocs.where((doc) {
      final matchesCategory = _selectedCategoryFilter == 'All' || doc.category == _selectedCategoryFilter;
      final q = _searchController.text.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          doc.documentName.toLowerCase().contains(q) ||
          doc.category.toLowerCase().contains(q) ||
          (doc.notes ?? '').toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Scan Document',
            onPressed: () {
              Navigator.pushNamed(context, Routes.documentScanner);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search documents by name or notes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Category Chips Bar
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                'All',
                ...DocumentCategories.defaultList,
              ].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryFilter = cat;
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Documents List View
          Expanded(
            child: docProvider.isLoading
                ? const LoadingIndicatorWidget(message: 'Loading documents...')
                : filteredDocs.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Documents Found',
                        message: _selectedCategoryFilter != 'All'
                            ? 'No documents under "$_selectedCategoryFilter" category.'
                            : 'Upload student certificates or documents to manage them here.',
                        icon: Icons.folder_open_rounded,
                        buttonText: 'Upload Document',
                        onButtonPressed: () {
                          Navigator.pushNamed(context, Routes.addDocument);
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => docProvider.loadAllDocuments(),
                        child: ListView.builder(
                          itemCount: filteredDocs.length,
                          padding: const EdgeInsets.only(bottom: 80, top: 4),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.documentViewer,
                                  arguments: doc,
                                );
                              },
                              onOpen: () {
                                Navigator.pushNamed(
                                  context,
                                  Routes.documentViewer,
                                  arguments: doc,
                                );
                              },
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Document?'),
                                    content: Text('Delete "${doc.documentName}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await docProvider.deleteDocument(doc.id, doc.studentId);
                                  docProvider.loadAllDocuments();
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addDocument);
        },
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload Document'),
      ),
    );
  }
}
