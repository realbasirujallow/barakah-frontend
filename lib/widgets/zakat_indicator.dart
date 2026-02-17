import 'package:flutter/material.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ZakatIndicator extends StatelessWidget {
  final double totalValue;
  final double zakatAmount;
  final bool zakatDue;

  static const double nisabThreshold = 5686.20;

  const ZakatIndicator({
    super.key,
    required this.totalValue,
    required this.zakatAmount,
    required this.zakatDue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final progress = (totalValue / nisabThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate, color: AppTheme.deepGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Zakat Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: zakatDue
                      ? AppTheme.deepGreen.withAlpha(25)
                      : Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  zakatDue ? 'Due' : 'Not Due',
                  style: TextStyle(
                    color: zakatDue ? AppTheme.deepGreen : Colors.orange[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                zakatDue ? AppTheme.deepGreen : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(totalValue),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              Text(
                'Nisab: ${currencyFormat.format(nisabThreshold)}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),

          if (zakatDue) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Zakat: ${currencyFormat.format(zakatAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepGreen,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '2.5%',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
