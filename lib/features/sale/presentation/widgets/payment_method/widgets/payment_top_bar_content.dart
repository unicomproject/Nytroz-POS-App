import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../payment_method_style.dart';

class PaymentTopBarContent extends ConsumerStatefulWidget {
  const PaymentTopBarContent({super.key});

  @override
  ConsumerState<PaymentTopBarContent> createState() =>
      _PaymentTopBarContentState();
}

class _PaymentTopBarContentState extends ConsumerState<PaymentTopBarContent> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceActivationProvider).deviceContext;
    final online =
        device != null && device.isTrusted && device.deviceId.trim().isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 690;
      return Row(children: [
        Expanded(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.credit_card_rounded,
                  color: PaymentMethodStyle.orange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proceed to Payment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900, color: Colors.black)),
                    const Text('Review sale and select a payment method.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: PaymentMethodStyle.navy, fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 18),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: online ? const Color(0xFF00B52D) : Colors.orange),
            ),
            child: Row(children: [
              CircleAvatar(
                  radius: 5,
                  backgroundColor:
                      online ? const Color(0xFF00C832) : Colors.orange),
              const SizedBox(width: 9),
              Text(online ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                      color: online ? const Color(0xFF00D438) : Colors.orange,
                      fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 12),
          Text(_clock(_now),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ]);
    });
  }
}

String _clock(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:${value.minute.toString().padLeft(2, '0')} '
      '${value.hour >= 12 ? 'PM' : 'AM'}';
}
