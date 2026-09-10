import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final VoidCallback? onReplace;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
    required this.onOpen,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = document.fileType.toLowerCase().contains('pdf') ||
        document.filePath.toLowerCase().endsWith('.pdf');
    final fileExists = File(document.filePath).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail / Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isPdf
                      ? Colors.red.withOpacity(0.12)
                      : theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  image: !isPdf && fileExists
                      ? DecorationImage(
                          image: FileImage(File(document.filePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: isPdf || !fileExists
                    ? Icon(
                        isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                        color: isPdf ? Colors.red : theme.colorScheme.primary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.documentName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploaded: ${DateFormatter.formatIsoDate(document.uploadedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                tooltip: 'Open File',
                onPressed: onOpen,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                tooltip: 'More Actions',
                onSelected: (action) {
                  if (action == 'view') {
                    onTap();
                  } else if (action == 'replace' && onReplace != null) {
                    onReplace!();
                  } else if (action == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  if (onReplace != null)
                    const PopupMenuItem(
                      value: 'replace',
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Replace File'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
