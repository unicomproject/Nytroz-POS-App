import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/pos_session/pos_session_provider.dart';
import '../providers/device_activation_provider.dart';
import '../widgets/device_activation_form.dart';

class DeviceActivationScreen extends ConsumerStatefulWidget {
  const DeviceActivationScreen({super.key});

  @override
  ConsumerState<DeviceActivationScreen> createState() =>
      _DeviceActivationScreenState();
}

class _DeviceActivationScreenState
    extends ConsumerState<DeviceActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  var _checkedCurrentDevice = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activationState = ref.watch(deviceActivationProvider);
    final sessionContext = ref.watch(posSessionContextProvider);

    if (!_checkedCurrentDevice && !activationState.isTrusted) {
      _checkedCurrentDevice = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final isTrusted = await ref
            .read(deviceActivationProvider.notifier)
            .refreshCurrentDevice(deviceName: sessionContext.deviceName);

        if (isTrusted && mounted) {
          context.go('/pos/open-till');
        }
      });
    }

    if (activationState.isTrusted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/pos/open-till');
        }
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StadiumBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrandHeader(title: '${sessionContext.brandName} POS'),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: DeviceActivationForm(
                          formKey: _formKey,
                          codeController: _codeController,
                          isSubmitting: activationState.isSubmitting,
                          errorMessage: activationState.errorMessage,
                          onSubmit: _submit,
                        ),
                      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionContext = ref.read(posSessionContextProvider);
    final activated =
        await ref.read(deviceActivationProvider.notifier).activate(
              activationCode: _codeController.text,
              deviceName: sessionContext.deviceName,
            );

    if (activated && mounted) {
      context.go('/pos/open-till');
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E7BFF), Color(0xFF003CFF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.hexagon_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StadiumBackground extends StatelessWidget {
  const _StadiumBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000817),
            Color(0xFF001A3A),
            Color(0xFF06275C),
            Color(0xFF061E21),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _StadiumBackgroundPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StadiumBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF083E23), Color(0xFF0F5A30)],
      ).createShader(
        Rect.fromLTWH(0, size.height * .78, size.width, size.height * .22),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .78, size.width, size.height * .22),
      fieldPaint,
    );

    final bowlPaint = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final top = size.height * (.34 + i * .075);
      canvas.drawArc(
        Rect.fromLTWH(
          -size.width * .08,
          top,
          size.width * 1.16,
          size.height * .28,
        ),
        3.28,
        3.0,
        false,
        bowlPaint,
      );
    }

    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
        Offset(size.width * .12, size.height * .37), 8, lightPaint);
    canvas.drawCircle(
        Offset(size.width * .88, size.height * .30), 8, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
