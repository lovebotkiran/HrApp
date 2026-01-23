import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class CandidatesListScreen extends ConsumerStatefulWidget {
  const CandidatesListScreen({super.key});

  @override
  ConsumerState<CandidatesListScreen> createState() =>
      _CandidatesListScreenState();
}

class _CandidatesListScreenState extends ConsumerState<CandidatesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidates'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ai-rankings'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Rank View'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search candidates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value.isEmpty ? null : value);
              },
            ),
          ),
          Expanded(
            child: candidatesAsync.when(
              data: (candidates) {
                if (candidates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No candidates found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            '${candidate.firstName[0]}${candidate.lastName[0]}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                            '${candidate.firstName} ${candidate.lastName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(candidate.email),
                            if (candidate.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(candidate.phone!),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/candidates/detail',
                            arguments: candidate.id,
                          );
                        },
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
                    Icon(Icons.error_outline,
                        size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text('Error loading candidates',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(candidatesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/candidates/create');
          ref.invalidate(candidatesProvider);
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Candidate'),
      ),
    );
  }
}
