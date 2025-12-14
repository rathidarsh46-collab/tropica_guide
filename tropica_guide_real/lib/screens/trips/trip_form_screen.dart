import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../services/trips_service.dart';
import '../../utils/date_format.dart';

class TripFormScreen extends StatefulWidget {
  final Trip? existingTrip;

  const TripFormScreen({super.key, this.existingTrip});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _collabEmails = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existingTrip != null;

  @override
  void initState() {
    super.initState();

    final t = widget.existingTrip;
    if (t != null) {
      _name.text = t.name;
      _city.text = t.destinationCity;
      _country.text = t.destinationCountry;
      _startDate = t.startDate;
      _endDate = t.endDate;

      // Join to a comma-separated string for easy editing
      _collabEmails.text = t.collaboratorEmails.join(', ');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    _collabEmails.dispose();
    super.dispose();
  }

  // Convert "a@b.com, c@d.com" into a clean list
  List<String> _parseEmails(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet() // prevent duplicates
        .toList();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked;

      // If end date exists but is before start, adjust end date
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Basic validation (keep it simple but real)
      if (_name.text.trim().isEmpty) throw 'Trip name is required.';
      if (_city.text.trim().isEmpty) throw 'Destination city is required.';
      if (_country.text.trim().isEmpty) throw 'Destination country is required.';
      if (_startDate == null) throw 'Start date is required.';
      if (_endDate == null) throw 'End date is required.';

      final emails = _parseEmails(_collabEmails.text);

      final service = context.read<TripsService>();

      if (_isEdit) {
        await service.updateTrip(
          tripId: widget.existingTrip!.id,
          name: _name.text.trim(),
          destinationCity: _city.text.trim(),
          destinationCountry: _country.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          collaboratorEmails: emails,
        );
      } else {
        await service.createTrip(
          name: _name.text.trim(),
          destinationCity: _city.text.trim(),
          destinationCountry: _country.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          collaboratorEmails: emails,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // return to MyTrips
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Trip' : 'Create Trip';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Trip name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Destination city'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _country,
              decoration: const InputDecoration(labelText: 'Destination country'),
            ),
            const SizedBox(height: 12),

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _pickStartDate,
                    child: Text(
                      _startDate == null ? 'Pick start date' : DateFormatters.mdy(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _pickEndDate,
                    child: Text(
                      _endDate == null ? 'Pick end date' : DateFormatters.mdy(_endDate!),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _collabEmails,
              decoration: const InputDecoration(
                labelText: 'Collaborator emails (comma-separated)',
                hintText: 'example: a@gmail.com, b@gmail.com',
              ),
            ),

            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const Spacer(),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Create trip'),
            ),
          ],
        ),
      ),
    );
  }
}
