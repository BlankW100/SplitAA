import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../models/receipt_result.dart';
import '../../settings/services/payment_profile_service.dart';

class ReceiptGenerator {
  static Future<Uint8List?> generate(
    ReceiptResult result,
    BuildContext context, {
    String? payerName,
  }) async {
    // Capture the inherited theme/MediaQuery now, before any async gap.
    final mqData = MediaQuery.of(context);
    final captured = InheritedTheme.capture(from: context, to: null);

    // Load the user's saved payment QR (if any) before building the widget,
    // since captureFromWidget needs a synchronous widget tree.
    Uint8List? qrBytes;
    final qrPath = await PaymentProfileService.getQrPath();
    if (qrPath != null) {
      try {
        qrBytes = await File(qrPath).readAsBytes();
      } catch (_) {}
    }

    final controller = ScreenshotController();
    return controller.captureFromWidget(
      captured.wrap(
        MediaQuery(
          data: mqData,
          child: _ReceiptWidget(
            result: result,
            payerName: payerName,
            paymentQr: qrBytes,
          ),
        ),
      ),
      pixelRatio: 2.0,
    );
  }
}

class _ReceiptWidget extends StatelessWidget {
  final ReceiptResult result;
  final String? payerName;
  final Uint8List? paymentQr;

  const _ReceiptWidget({required this.result, this.payerName, this.paymentQr});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const Text(
                'SPLITAA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                  color: Colors.black,
                ),
              ),
              // Payer name (for per-person split receipts)
              if (payerName != null && payerName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payerName!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _fmtDate(result.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.black),
              const SizedBox(height: 8),

              // Items
              ...result.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            item.quantity > 1 ? '${item.quantity}× ${item.name}' : item.name,
                            style: const TextStyle(fontSize: 13, color: Colors.black)),
                      ),
                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.grey),

              // Subtotal
              _row('Subtotal', result.subtotal, grey: true),

              // Fees
              ...result.fees.map((fee) {
                final amount = fee.compute(result.subtotal);
                final label =
                    '${fee.label} (${fee.isPercentage ? '${fee.value}%' : 'RM ${fee.value.toStringAsFixed(2)}'})';
                return _row(label, amount, grey: true, isDiscount: fee.isDiscount);
              }),

              const Divider(color: Colors.black),

              // Total
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black),
                      ),
                    ),
                    Text(
                      'RM ${result.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Payment QR (user-uploaded) or a hint if none is set.
              if (paymentQr != null) ...[
                Image.memory(paymentQr!, width: 140, height: 140, fit: BoxFit.contain),
                const SizedBox(height: 6),
                const Text('Scan to pay', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ] else
                const Text(
                  'Add a payment QR in Settings\nto show it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),

              const SizedBox(height: 20),
              const Text(
                '— Generated by Splitaa —',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double amount,
      {bool grey = false, bool isDiscount = false}) {
    final color = isDiscount ? Colors.green.shade700 : (grey ? Colors.grey.shade600 : Colors.black);
    final sign = isDiscount ? '-' : (amount < 0 ? '-' : '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: color))),
          Text(
            '$sign RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
