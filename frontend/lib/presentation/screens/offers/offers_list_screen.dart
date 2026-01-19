import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class OffersListScreen extends ConsumerStatefulWidget {
  const OffersListScreen({super.key});

  @override
  ConsumerState<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends ConsumerState<OffersListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'All' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Draft', child: Text('Draft')),
              const PopupMenuItem(value: 'Pending Approval', child: Text('Pending Approval')),
              const PopupMenuItem(value: 'Sent', child: Text('Sent')),
              const PopupMenuItem(value: 'Accepted', child: Text('Accepted')),
              const PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text('No offers found', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text('Offer #${offer.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 16),
                          const SizedBox(width: 4),
                          Text('\$${_formatCurrency(offer.baseSalary)}'),
                        ],
                      ),
                      if (offer.bonus != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard, size: 16),
                            const SizedBox(width: 4),
                            Text('Bonus: \$${_formatCurrency(offer.bonus!)}'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text('Start: ${_formatDate(offer.startDate)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event_busy, size: 16),
                          const SizedBox(width: 4),
                          Text('Expires: ${_formatDate(offer.expirationDate)}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(offer.status),
                    backgroundColor: _getStatusColor(offer.status),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Error loading offers', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(offersProvider(_selectedStatus)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/offers/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Offer'),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return AppTheme.textSecondary.withOpacity(0.2);
      case 'Pending Approval':
        return AppTheme.warningColor.withOpacity(0.2);
      case 'Sent':
        return AppTheme.infoColor.withOpacity(0.2);
      case 'Accepted':
        return AppTheme.successColor.withOpacity(0.2);
      case 'Rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }
}
