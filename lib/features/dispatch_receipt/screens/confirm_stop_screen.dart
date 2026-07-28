import 'package:flutter/material.dart';
import '../models/dispatch_receipt_models.dart';
import '../services/dispatch_receipt_service.dart';

class ConfirmStopScreen extends StatefulWidget {
  final String receiptId;
  final DispatchReceiptStop stop;

  const ConfirmStopScreen({
    super.key,
    required this.receiptId,
    required this.stop,
  });

  @override
  State<ConfirmStopScreen> createState() => _ConfirmStopScreenState();
}

class _ConfirmStopScreenState extends State<ConfirmStopScreen> {
  final _service = DispatchReceiptService();
  final Set<String> _missingIds = {};
  final Set<String> _damagedIds = {};
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _service.confirmStop(
        widget.receiptId,
        widget.stop.stopOrder,
        ConfirmStopReceiptDto(
          missingShipmentIds: _missingIds.toList(),
          damagedShipmentIds: _damagedIds.toList(),
          notes: _notesCtrl.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirm Stop ${widget.stop.stopOrder}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.stop.shipments.length,
              itemBuilder: (context, index) {
                final s = widget.stop.shipments[index];
                return ListTile(
                  title: Text(s.ticketNumber),
                  subtitle: Text(s.itemDescription),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilterChip(
                        label: const Text('Missing'),
                        selected: _missingIds.contains(s.id),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _missingIds.add(s.id);
                            } else {
                              _missingIds.remove(s.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Damaged'),
                        selected: _damagedIds.contains(s.id),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _damagedIds.add(s.id);
                            } else {
                              _damagedIds.remove(s.id);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Confirm Receipt'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
