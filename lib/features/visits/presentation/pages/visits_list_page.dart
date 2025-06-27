import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../manager/visit_cubit.dart';
import '../widgets/visit_card.dart';
import '../../domain/usecases/get_visit_stats.dart';

class VisitsListPage extends StatefulWidget {
  const VisitsListPage({super.key});

  @override
  State<VisitsListPage> createState() => _VisitsListPageState();
}

class _VisitsListPageState extends State<VisitsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitCubit>().loadVisitsAndDependencies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visits Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VisitCubit>().loadVisitsAndDependencies();
              _searchController.clear();
              setState(() {
                _selectedStatusFilter = null;
              });
            },
          ),
        ],
      ),
      body: BlocConsumer<VisitCubit, VisitState>(
        listener: (context, state) {
          if (state is VisitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is VisitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is VisitLoaded) {
            final customersMap = {for (var c in state.customers) c.id: c};
            final activitiesMap = {for (var a in state.activities) a.id: a};

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildVisitStatistics(state.stats),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search visits (customer, location, notes)',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<VisitCubit>().filterVisits('', _selectedStatusFilter);
                            },
                          )
                              : null,
                        ),
                        onChanged: (query) {
                          context.read<VisitCubit>().filterVisits(query, _selectedStatusFilter);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: _selectedStatusFilter,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Statuses')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value;
                          });
                          context.read<VisitCubit>().filterVisits(_searchController.text, _selectedStatusFilter);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.filteredVisits.isEmpty
                      ? const Center(child: Text('No visits found.'))
                      : ListView.builder(
                    itemCount: state.filteredVisits.length,
                    itemBuilder: (context, index) {
                      final visit = state.filteredVisits[index];
                      final customer = customersMap[visit.customerId];
                      final activitiesDone = visit.activitiesDoneIds
                          ?.map((id) => activitiesMap[id]?.description ?? 'Unknown Activity')
                          .toList();

                      return VisitCard(
                        visit: visit,
                        customerName: customer?.name ?? 'Unknown Customer',
                        activitiesDone: activitiesDone ?? [],
                        onTap: () {
                          // Navigate to visit detail page
                          context.go('/visit_detail/${visit.id}');
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is VisitError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () => context.read<VisitCubit>().loadVisitsAndDependencies(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Press the refresh button to load visits.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/add_visit');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVisitStatistics(VisitStats stats) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Visits', stats.totalVisits),
                _buildStatItem('Completed', stats.completedVisits),
                _buildStatItem('Pending', stats.pendingVisits),
                _buildStatItem('Cancelled', stats.cancelledVisits),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}