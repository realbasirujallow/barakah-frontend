import 'package:flutter/material.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdatePrice;

  const AssetCard({
    super.key,
    required this.asset,
    this.onDelete,
    this.onUpdatePrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.deepGreen.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                asset.typeIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  asset.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(asset.value),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.deepGreen,
                ),
              ),
              if (onUpdatePrice != null)
                GestureDetector(
                  onTap: onUpdatePrice,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 2),
                        Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Delete button
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
