import 'package:flutter_riverpod/flutter_riverpod.dart';

class PosPrintReceiptOption {
  const PosPrintReceiptOption({
    required this.id,
    required this.label,
    required this.subtitle,
  });

  final String id;
  final String label;
  final String subtitle;
}

class PosPrintReceiptOptionsState {
  const PosPrintReceiptOptionsState({
    required this.selectedPrinterId,
    required this.selectedPaperSizeId,
    required this.selectedCopies,
  });

  final String selectedPrinterId;
  final String selectedPaperSizeId;
  final int selectedCopies;

  PosPrintReceiptOptionsState copyWith({
    String? selectedPrinterId,
    String? selectedPaperSizeId,
    int? selectedCopies,
  }) {
    return PosPrintReceiptOptionsState(
      selectedPrinterId: selectedPrinterId ?? this.selectedPrinterId,
      selectedPaperSizeId: selectedPaperSizeId ?? this.selectedPaperSizeId,
      selectedCopies: selectedCopies ?? this.selectedCopies,
    );
  }
}

const posPrintReceiptPrinters = <PosPrintReceiptOption>[
  PosPrintReceiptOption(
    id: 'epson-tm-t82iii-usb',
    label: 'Epson TM-T82III (USB)',
    subtitle: 'Receipt Printer',
  ),
  PosPrintReceiptOption(
    id: 'star-tsp143',
    label: 'Star TSP143 (USB)',
    subtitle: 'Receipt Printer',
  ),
];

const posPrintReceiptPaperSizes = <PosPrintReceiptOption>[
  PosPrintReceiptOption(
    id: '80mm',
    label: '80mm (Receipt)',
    subtitle: 'Width: 80mm',
  ),
  PosPrintReceiptOption(
    id: '58mm',
    label: '58mm (Receipt)',
    subtitle: 'Width: 58mm',
  ),
];

const posPrintReceiptCopyOptions = <int>[1, 2, 3];

class PosPrintReceiptOptionsNotifier
    extends StateNotifier<PosPrintReceiptOptionsState> {
  PosPrintReceiptOptionsNotifier()
      : super(
          const PosPrintReceiptOptionsState(
            selectedPrinterId: 'epson-tm-t82iii-usb',
            selectedPaperSizeId: '80mm',
            selectedCopies: 1,
          ),
        );

  void selectPrinter(String id) {
    state = state.copyWith(selectedPrinterId: id);
  }

  void selectPaperSize(String id) {
    state = state.copyWith(selectedPaperSizeId: id);
  }

  void selectCopies(int copies) {
    state = state.copyWith(selectedCopies: copies);
  }
}

final posPrintReceiptOptionsProvider = StateNotifierProvider<
    PosPrintReceiptOptionsNotifier, PosPrintReceiptOptionsState>(
  (ref) => PosPrintReceiptOptionsNotifier(),
);
