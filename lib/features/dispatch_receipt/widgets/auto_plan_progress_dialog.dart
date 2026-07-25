import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dispatch_receipt_models.dart';

class AutoPlanProgressDialog extends StatefulWidget {
  const AutoPlanProgressDialog({required this.operation, super.key});

  final Future<AutoPlanDispatchResult> Function() operation;

  @override
  State<AutoPlanProgressDialog> createState() => _AutoPlanProgressDialogState();
}

class _AutoPlanProgressDialogState extends State<AutoPlanProgressDialog> {
  static const _steps = [
    _PlanningStep(
      'Scanning shipments',
      'Finding unassigned packages ready for dispatch.',
      Icons.inventory_2_outlined,
    ),
    _PlanningStep(
      'Validating destinations',
      'Checking active destination branches and coordinates.',
      Icons.warehouse_outlined,
    ),
    _PlanningStep(
      'Checking truck capacity',
      'Reviewing available drivers, trucks, and carrying limits.',
      Icons.local_shipping_outlined,
    ),
    _PlanningStep(
      'Building the road matrix',
      'Calculating road travel times between branches with OSRM.',
      Icons.route_outlined,
    ),
    _PlanningStep(
      'Optimizing the dispatch',
      'Assigning packages and ordering stops with OR-Tools.',
      Icons.auto_awesome_outlined,
    ),
    _PlanningStep(
      'Creating dispatch receipts',
      'Saving routes, stops, drivers, and package assignments.',
      Icons.receipt_long_outlined,
    ),
  ];

  Timer? _progressTimer;
  double _progress = 0.04;
  Object? _error;
  bool _running = true;

  int get _activeStep {
    if (_progress < 0.17) return 0;
    if (_progress < 0.31) return 1;
    if (_progress < 0.46) return 2;
    if (_progress < 0.64) return 3;
    if (_progress < 0.82) return 4;
    return 5;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    _progressTimer?.cancel();
    setState(() {
      _progress = 0.04;
      _error = null;
      _running = true;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _progress >= 0.94) return;
      setState(() {
        final increment = switch (_progress) {
          < 0.17 => 0.018,
          < 0.31 => 0.013,
          < 0.46 => 0.009,
          < 0.64 => 0.006,
          < 0.82 => 0.004,
          _ => 0.0015,
        };
        _progress = (_progress + increment).clamp(0, 0.94).toDouble();
      });
    });

    try {
      final result = await widget.operation();
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _progress = 1;
        _running = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _error = error;
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasError = _error != null;
    final percentage = (_progress * 100).round();

    return PopScope(
      canPop: !_running,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (hasError ? colors.error : colors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : _progress == 1
                          ? Icons.check_circle_outline_rounded
                          : Icons.auto_awesome_rounded,
                      color: hasError ? colors.error : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasError
                              ? 'Unable to create dispatch plan'
                              : _progress == 1
                              ? 'Optimization complete'
                              : 'Planning your dispatch',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasError
                              ? 'The planner stopped before creating the plan.'
                              : 'Please keep this window open while we prepare the best route.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasError)
                    Text(
                      '$percentage%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              if (hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cleanError(_error!),
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 9,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _progress == 1
                      ? 'Your optimized receipts are ready.'
                      : 'Estimated progress — completion waits for the server.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 330),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < _steps.length; index++)
                          _StepRow(
                            step: _steps[index],
                            state: _progress == 1 || index < _activeStep
                                ? _StepState.complete
                                : index == _activeStep
                                ? _StepState.active
                                : _StepState.pending,
                            isLast: index == _steps.length - 1,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hasError) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _running ? null : _run,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.state,
    required this.isLast,
  });

  final _PlanningStep step;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = state == _StepState.active;
    final isComplete = state == _StepState.complete;
    final foreground = isActive || isComplete
        ? colors.primary
        : colors.onSurfaceVariant.withValues(alpha: 0.55);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary
                        : isComplete
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: isActive
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isComplete ? Icons.check_rounded : step.icon,
                          size: 17,
                          color: foreground,
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isComplete
                          ? colors.primaryContainer
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: isActive || isComplete
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningStep {
  const _PlanningStep(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

enum _StepState { pending, active, complete }
