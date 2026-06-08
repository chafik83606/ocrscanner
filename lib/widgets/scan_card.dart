import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_model.dart';

class ScanCard extends StatelessWidget {
  const ScanCard({super.key, required this.scan, required this.onTap});
  final ScanModel scan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniature
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: scan.imagePath.isNotEmpty
                    ? Image.file(
                        File(scan.imagePath),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.document_scanner),
                      ),
              ),
              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.title ??
                          'Scan du ${DateFormat('dd/MM/yyyy').format(scan.createdAt)}',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scan.extractedText.isEmpty
                          ? '(aucun texte)'
                          : scan.extractedText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
