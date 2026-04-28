import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../router/app_router.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_widgets.dart';

class OtpScreen extends StatefulWidget {
  final OtpArgs args;

  const OtpScreen({super.key, required this.args});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _pinLength = 6;
  static const int _timerSeconds = 60;

  final _service = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(_pinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_pinLength, (_) => FocusNode());

  int _secondsLeft = _timerSeconds;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s s';
  }

  // ── OTP helpers ───────────────────────────────────────────────────────────

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _pinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    // Handle paste: if first box gets 6 chars
    if (value.length == _pinLength) {
      for (int i = 0; i < _pinLength; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[_pinLength - 1].requestFocus();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────

  Future<void> _resend() async {
    try {
      if (widget.args.flow == AuthFlow.register) {
        await _service.initiateRegister(InitiateRegisterRequest(
          name: widget.args.name ?? '',
          email: widget.args.email,
        ));
      } else {
        await _service.forgotPassword(
            ForgotPasswordRequest(email: widget.args.email));
      }
      _startTimer();
      if (mounted) showSuccessSnack(context, 'លេខកូដថ្មីត្រូវបានផ្ញើ');
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចផ្ញើលេខកូដបន្ថែមបានទេ');
    }
  }

  // ── Submit OTP ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_otp.length < _pinLength) {
      showErrorDialog(context, 'សូមបញ្ចូលលេខកូដ ${ _pinLength} ខ្ទង់ឱ្យបានពេញ');
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.args.flow == AuthFlow.register) {
        final res = await _service.verifyEmail(
            VerifyEmailRequest(email: widget.args.email, otp: _otp));
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.setPassword,
            arguments: SetPasswordArgs(
              flow: widget.args.flow,
              setupToken: res.setupToken,
            ),
          );
        }
      } else {
        // Forgot password flow
        final res = await _service.verifyOtp(
            VerifyOtpRequest(email: widget.args.email, otp: _otp));
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.setPassword,
            arguments: SetPasswordArgs(
              flow: widget.args.flow,
              resetToken: res.resetToken,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) showErrorDialog(context, e.message);
    } catch (_) {
      if (mounted) showErrorDialog(context, 'មិនអាចផ្ទៀងផ្ទាត់លេខកូដបានទេ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AuthHeaderWithBack(onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // ── Title ─────────────────────────────────────────────
                  const Text(
                    'ផ្ទៀងផ្ទាត់គណនី',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2D3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'សុវត្ថិភាព, ទំនុកចិត្ត និង រហ័ស',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7A8D)),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ────────────────────────────────────────
                  const Text(
                    'សូមពិនិត្យមើលប្រអប់សាររបស់លោកអ្នក, រួចធ្វើការបញ្ចូលលេខសម្ងាត់ នៅខាងក្រោម:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 6-box PIN input ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_pinLength, (i) {
                      return SizedBox(
                        width: 46,
                        height: 52,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (e) => _onKeyEvent(i, e),
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _onDigitChanged(i, v),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2D3D),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDE3EE)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDE3EE)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF4A8DDB), width: 2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ── Timer / Resend ─────────────────────────────────────
                  _secondsLeft > 0
                      ? RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7A8D)),
                            children: [
                              const TextSpan(text: 'កំណត់លេខកូដម្តងទៀត: '),
                              TextSpan(
                                text: _timerLabel,
                                style: const TextStyle(
                                  color: Color(0xFF4A8DDB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: _resend,
                          child: const Text(
                            'សំណើ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4A8DDB),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF4A8DDB),
                            ),
                          ),
                        ),
                  const SizedBox(height: 40),

                  // ── Submit button ──────────────────────────────────────
                  AuthButton(
                    label: 'បញ្ជូន',
                    onPressed: _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}