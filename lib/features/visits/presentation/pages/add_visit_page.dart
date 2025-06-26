import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../manager/visit_cubit.dart';

class AddVisitPage extends StatefulWidget {
  const AddVisitPage({super.key});

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCustomerId;
  DateTime _selectedDate = DateTime.now();
  String _status = 'Pending';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<int> _selectedActivityIds = [];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer.')),
        );
        return;
      }

      context.read<VisitCubit>().addNewVisit(
        customerId: _selectedCustomerId!,
        visitDate: _selectedDate,
        status: _status,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        activitiesDoneIds: _selectedActivityIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Visit'),
      ),
      body: BlocConsumer<VisitCubit, VisitState>(
        listener: (context, state) {
          if (state is VisitError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is VisitLoaded && state.visits.isNotEmpty && state.visits.last.notes == _notesController.text.trim()) {
            // Simple check to see if the visit was added. A better way would be
            // to have a specific state for `VisitAddedSuccess`.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Visit added successfully!')),
            );
            context.go('/'); // Go back to visits list
          }
        },
        builder: (context, state) {
          if (state is VisitLoading && _selectedCustomerId == null) { // Show loading only initially
            return const Center(child: CircularProgressIndicator());
          } else if (state is VisitLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Customer'),
                      value: _selectedCustomerId,
                      items: state.customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text(customer.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Visit Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status'),
                      value: _status,
                      items: ['Pending', 'Completed', 'Cancelled'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) => value!.isEmpty ? 'Please enter a location' : null,
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Activities Done:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...state.activities.map((activity) {
                      return CheckboxListTile(
                        title: Text(activity.description),
                        value: _selectedActivityIds.contains(activity.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedActivityIds.add(activity.id);
                            } else {
                              _selectedActivityIds.remove(activity.id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 24.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: state is VisitLoading ? null : _submitForm,
                        child: state is VisitLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Add Visit'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is VisitError) {
            return Center(child: Text('Error loading dependencies: ${state.message}'));
          }
          return const Center(child: Text('Loading form...')); // Should ideally not happen after initial load
        },
      ),
    );
  }
}