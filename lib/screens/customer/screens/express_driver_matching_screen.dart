import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../features/auth/tokens/token_storage.dart';
import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
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
          _messageFrom(response.body, 'Unable to check delivery'),
        );
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString().toUpperCase() ?? 'PENDING';
      if (status != 'PENDING') {
        if (status == 'CANCELLED' || status == 'FAILED') {
          throw Exception('This delivery is no longer active.');
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
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
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
          _messageFrom(response.body, 'Unable to retry driver matching'),
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
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
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
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          title: const Text(
            'Finding a driver',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Text(
                      _expired
                          ? 'No driver accepted in time'
                          : 'Broadcasting your delivery',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _expired
                          ? 'You can retry to notify currently available drivers nearby.'
                          : 'Nearby drivers can accept this request. The first acceptance reserves the delivery.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 34),
                    SizedBox.square(
                      dimension: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: _loading ? null : progress,
                              strokeWidth: 13,
                              strokeCap: StrokeCap.round,
                              backgroundColor: AppColors.line,
                              color: _expired
                                  ? AppColors.danger
                                  : AppColors.blue,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loading ? '...' : '$_remainingSeconds',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 52,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'seconds',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _MatchingStep(
                      icon: Icons.check_circle,
                      label: 'Delivery request created',
                      completed: true,
                    ),
                    _MatchingStep(
                      icon: Icons.cell_tower,
                      label: 'Notifying nearby available drivers',
                      completed: !_expired,
                      active: !_expired,
                    ),
                    const _MatchingStep(
                      icon: Icons.delivery_dining,
                      label: 'Waiting for the first driver to accept',
                      active: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Broadcast attempt $_attempt',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                    if (_expired) ...[
                      const SizedBox(height: 24),
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
                            _retrying ? 'Broadcasting...' : 'Retry matching',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
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
