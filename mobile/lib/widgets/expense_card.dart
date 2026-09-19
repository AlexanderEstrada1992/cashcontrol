import 'package:flutter/material.dart';

import '../core/theme/cashcontrol_theme.dart';
import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.showStatus = true,
  });

  final Expense expense;
  final VoidCallback? onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CashControlColors>()!;
    final isPending = expense.isPending;
    final statusColor = isPending ? colors.warning : colors.success;
    final statusLabel = isPending ? 'Pendiente de sincronización' : 'Sincronizado';

    return Semantics(
      label: '${expense.description} por ${expense.amount.toStringAsFixed(2)} euros',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(colors.radiusMd),
          child: Padding(
            padding: EdgeInsets.all(colors.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(colors.radiusMd),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: colors.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description.isNotEmpty ? expense.description : 'Gasto sin descripción',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: colors.spacingXs),
                      Text(
                        '€ ${expense.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showStatus) ...[
                        SizedBox(height: colors.spacingSm),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: statusColor),
                            SizedBox(width: colors.spacingSm),
                            Text(
                              statusLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (expense.hasReceiptPhoto || expense.hasLocation) ...[
                        SizedBox(height: colors.spacingSm),
                        Row(
                          children: [
                            if (expense.hasReceiptPhoto) ...[
                              Icon(Icons.photo_camera_outlined, size: 16, color: colors.textSecondary),
                              SizedBox(width: colors.spacingXs),
                              Text('Foto', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                              SizedBox(width: colors.spacingMd),
                            ],
                            if (expense.hasLocation) ...[
                              Icon(Icons.location_on_outlined, size: 16, color: colors.textSecondary),
                              SizedBox(width: colors.spacingXs),
                              Text('Ubicación', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
