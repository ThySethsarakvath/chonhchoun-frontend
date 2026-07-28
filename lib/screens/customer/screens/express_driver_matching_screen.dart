import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../features/auth/tokens/token_storage.dart';
import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
import '../../../shared/theme/app_tokens.dart';
import 'customer_express_tracking_screen.dart';

class ExpressDriverMatchingScreen extends StatefulWidget {
  const ExpressDriverMatchingScreen({super.key, required this.packageId});

  final String packageId;

  @override
  State<ExpressDriverMatchingScreen> createState() =>
      _ExpressDriverMatchingScreenState();
}

class _ExpressDriverMatchingScreenState
    extends State<ExpressDriverMatchingScreen> {
  static const int _broadcastSeconds = 300;

  Timer? _clockTimer;
  Timer? _pollTimer;
  DateTime? _expiresAt;
  int _remainingSeconds = _broadcastSeconds;
  int _attempt = 1;
  bool _loading = true;
  bool _retrying = false;
  bool _requestInFlight = false;
  bool _openingTracking = false;
  String? _error;

  bool get _expired => !_loading && _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refresh(silent: true),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_requestInFlight || _openingTracking) return;
    _requestInFlight = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/packages/${widget.packageId}'),
        headers: await _headers(),
      );
      if (response.statusCode != 200) {
        throw Exception(
          _messageFrom(response.body, 'មិនអាចពិនិត្យការដឹកជញ្ជូនបានទេ'),
        );
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString().toUpperCase() ?? 'PENDING';
      if (status != 'PENDING') {
        if (status == 'CANCELLED' || status == 'FAILED') {
          throw Exception('ការដឹកជញ្ជូននេះលែងដំណើរការហើយ។');
        }
        _openTracking();
        return;
      }

      final expiresAt = DateTime.tryParse(
        data['broadcastExpiresAt']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() {
        _expiresAt =
            expiresAt ??
            _expiresAt ??
            DateTime.now().add(const Duration(seconds: _broadcastSeconds));
        _attempt = (data['broadcastAttempt'] as num?)?.toInt() ?? _attempt;
        _loading = false;
        _error = null;
      });
      _updateCountdown();
    } catch (error) {
      if (!mounted || silent) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _loading = false;
        _error = RegExp(r'[\u1780-\u17FF]').hasMatch(message)
            ? message
            : 'មិនអាចពិនិត្យការស្វែងរកអ្នកបើកបរបានទេ។';
      });
    } finally {
      _requestInFlight = false;
    }
  }

  void _updateCountdown() {
    if (!mounted || _expiresAt == null) return;
    final milliseconds = _expiresAt!.difference(DateTime.now()).inMilliseconds;
    final seconds = milliseconds <= 0
        ? 0
        : (milliseconds / Duration.millisecondsPerSecond).ceil();
    if (seconds != _remainingSeconds) {
      setState(() => _remainingSeconds = seconds.clamp(0, _broadcastSeconds));
    }
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/packages/${widget.packageId}/broadcast/retry'),
        headers: await _headers(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          _messageFrom(response.body, 'មិនអាចស្វែងរកអ្នកបើកបរម្ដងទៀតបានទេ'),
        );
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final expiresAt = DateTime.tryParse(
        data['broadcastExpiresAt']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() {
        _expiresAt =
            expiresAt ??
            DateTime.now().add(const Duration(seconds: _broadcastSeconds));
        _attempt = (data['broadcastAttempt'] as num?)?.toInt() ?? _attempt + 1;
        _remainingSeconds = _broadcastSeconds;
      });
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        setState(
          () => _error = RegExp(r'[\u1780-\u17FF]').hasMatch(message)
              ? message
              : 'មិនអាចស្វែងរកអ្នកបើកបរម្ដងទៀតបានទេ។',
        );
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  void _openTracking() {
    if (!mounted || _openingTracking) return;
    _openingTracking = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            CustomerExpressTrackingScreen(packageId: widget.packageId),
      ),
    );
  }

  String _messageFrom(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      final message = decoded['message'];
      if (message is List) return message.join('\n');
      if (message != null) return message.toString();
    } catch (_) {}
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / _broadcastSeconds;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(title: const Text('កំពុងស្វែងរកអ្នកបើកបរ')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.standard,
                      child: Text(
                        _expired
                            ? 'គ្មានអ្នកបើកបរទទួលយកទាន់ពេល'
                            : 'កំពុងផ្សព្វផ្សាយសំណើដឹកជញ្ជូនរបស់អ្នក',
                        key: ValueKey(_expired),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _expired
                          ? 'អ្នកអាចព្យាយាមម្ដងទៀត ដើម្បីជូនដំណឹងដល់អ្នកបើកបរដែលនៅជិត និងទំនេរ។'
                          : 'អ្នកបើកបរដែលនៅជិតអាចទទួលយកសំណើនេះ។ អ្នកដែលទទួលមុនគេនឹងទទួលបានការដឹកជញ្ជូននេះ។',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _CountdownDial(
                      loading: _loading,
                      expired: _expired,
                      progress: progress,
                      remainingSeconds: _remainingSeconds,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          const _MatchingStep(
                            icon: Icons.check_circle_rounded,
                            label: 'បានបង្កើតសំណើដឹកជញ្ជូន',
                            completed: true,
                          ),
                          _MatchingStep(
                            icon: Icons.cell_tower_rounded,
                            label: 'កំពុងជូនដំណឹងដល់អ្នកបើកបរដែលនៅជិត',
                            completed: !_expired,
                            active: !_expired,
                          ),
                          const _MatchingStep(
                            icon: Icons.delivery_dining_rounded,
                            label: 'កំពុងរង់ចាំអ្នកបើកបរដំបូងទទួលយក',
                            active: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ការផ្សព្វផ្សាយលើកទី $_attempt',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                    if (_expired) ...[
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _retrying ? null : _retry,
                          icon: _retrying
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            _retrying
                                ? 'កំពុងផ្សព្វផ្សាយ...'
                                : 'ស្វែងរកម្ដងទៀត',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blueDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownDial extends StatelessWidget {
  const _CountdownDial({
    required this.loading,
    required this.expired,
    required this.progress,
    required this.remainingSeconds,
  });

  final bool loading;
  final bool expired;
  final double progress;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final color = expired ? AppColors.danger : AppColors.blue;
    return Semantics(
      liveRegion: true,
      label: loading
          ? 'កំពុងពិនិត្យស្ថានភាពស្វែងរកអ្នកបើកបរ'
          : 'នៅសល់ $remainingSeconds វិនាទី',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimension = (constraints.maxWidth * 0.55).clamp(190.0, 230.0);
          return Container(
            width: dimension + 28,
            height: dimension + 28,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.06),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: dimension,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: loading ? null : progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.line,
                      color: color,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text(
                          loading ? '…' : '$remainingSeconds',
                          key: ValueKey(loading ? -1 : remainingSeconds),
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontSize: 52),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        expired ? 'ផុតកំណត់' : 'វិនាទី',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: expired
                                  ? AppColors.danger
                                  : AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatchingStep extends StatelessWidget {
  const _MatchingStep({
    required this.icon,
    required this.label,
    this.completed = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = completed || active ? AppColors.blue : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (completed)
            const Icon(Icons.check, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}
