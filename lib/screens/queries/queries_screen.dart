import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/query_model.dart';
import '../../providers/query_provider.dart';

class QueriesScreen extends StatelessWidget {
  const QueriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorgularım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<QueryProvider>(
        builder: (_, provider, child) {
          if (provider.queries.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('Henüz sorgu yok', style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 4),
                Text('Haritadan bir eczane seçip ilaç sorgulayın', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.queries.length,
            itemBuilder: (_, i) => _QueryCard(
              query: provider.queries[i],
              onUpdateStatus: (isAvailable) =>
                  provider.updateQueryStatus(provider.queries[i].id, isAvailable),
              onCancel: () => provider.cancelQuery(provider.queries[i].id),
            ),
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tüm Sorguları Sil'),
        content: const Text('Tüm sorgu geçmişi silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              context.read<QueryProvider>().clearAll();
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  final QueryModel query;
  final void Function(bool) onUpdateStatus;
  final VoidCallback onCancel;

  const _QueryCard({required this.query, required this.onUpdateStatus, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIcon(status: query.status),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.drugList.length > 1
                            ? '${query.drugList.length} ilaç sorgusu'
                            : query.drugName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        query.statusLabel,
                        style: TextStyle(fontSize: 12, color: _statusColor(query.status)),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(query.timestamp),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            if (query.drugList.length > 1) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: query.drugList.map((d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.local_pharmacy_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(query.pharmacyName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.tag, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('Sorgu ID: ${query.id}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            ]),

            // Detaylı GPT yanıtı
            if (query.fullMessage != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showFullMessage(context, query),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Eczane yanıtını gör', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500))),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],

            // Kısa özet
            if (query.callMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(query.status).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor(query.status).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.record_voice_over_outlined, size: 14, color: _statusColor(query.status)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        query.callMessage!,
                        style: TextStyle(fontSize: 12, color: _statusColor(query.status)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Alternatif ilaç
            if (query.alternative != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.swap_horiz, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Alternatif: ${query.alternative}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ]),
            ],

            // Arama veya transkripsiyon devam ediyor
            if (query.status == QueryStatus.calling || query.status == QueryStatus.transcribing || query.status == QueryStatus.pending) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      query.status == QueryStatus.calling
                          ? 'Eczane aranıyor...'
                          : query.status == QueryStatus.transcribing
                              ? 'Ses analiz ediliyor...'
                              : 'Hazırlanıyor...',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('İptal'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],

            // WhatsApp bekliyor — manuel onay
            if (query.status == QueryStatus.sent) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Eczaneden cevap aldınız mı?', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mevcut'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.open,
                      side: const BorderSide(color: AppColors.open),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Yok'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullMessage(BuildContext context, QueryModel query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              _StatusIcon(status: query.status),
              const SizedBox(width: 10),
              Expanded(child: Text(query.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ]),
            const SizedBox(height: 4),
            Text(query.drugList.join(', '), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Eczane Yanıtı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                query.fullMessage ?? query.callMessage ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            if (query.alternative != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.swap_horiz, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text('Alternatif: ${query.alternative}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(QueryStatus status) {
    switch (status) {
      case QueryStatus.available:
        return AppColors.open;
      case QueryStatus.unavailable:
      case QueryStatus.error:
        return AppColors.error;
      case QueryStatus.calling:
      case QueryStatus.sent:
        return AppColors.duty;
      case QueryStatus.transcribing:
        return Colors.blue;
      case QueryStatus.noAnswer:
      case QueryStatus.timeout:
        return AppColors.closed;
      case QueryStatus.unclear:
        return Colors.orange;
      case QueryStatus.cancelled:
        return AppColors.textHint;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final QueryStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case QueryStatus.available:
        return const Icon(Icons.check_circle, color: AppColors.open, size: 24);
      case QueryStatus.unavailable:
        return const Icon(Icons.cancel, color: AppColors.error, size: 24);
      case QueryStatus.calling:
        return const Icon(Icons.phone_in_talk, color: AppColors.duty, size: 24);
      case QueryStatus.transcribing:
        return const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        );
      case QueryStatus.sent:
        return const Icon(Icons.schedule, color: AppColors.duty, size: 24);
      case QueryStatus.noAnswer:
        return const Icon(Icons.phone_missed, color: AppColors.closed, size: 24);
      case QueryStatus.unclear:
        return const Icon(Icons.help_outline, color: Colors.orange, size: 24);
      case QueryStatus.timeout:
        return const Icon(Icons.timer_off, color: AppColors.closed, size: 24);
      case QueryStatus.error:
        return const Icon(Icons.error_outline, color: AppColors.error, size: 24);
      case QueryStatus.cancelled:
        return const Icon(Icons.block, color: AppColors.textHint, size: 24);
      case QueryStatus.pending:
        return const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }
}
