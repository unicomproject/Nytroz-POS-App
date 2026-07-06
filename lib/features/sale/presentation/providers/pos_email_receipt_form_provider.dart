import 'package:flutter_riverpod/flutter_riverpod.dart';

const posEmailReceiptMessageMaxLength = 200;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmailReceiptAddress(String value) {
  final email = value.trim();
  return email.isNotEmpty && _emailPattern.hasMatch(email);
}

class PosEmailReceiptFormState {
  const PosEmailReceiptFormState({
    this.email = '',
    this.message = '',
    this.emailTouched = false,
  });

  final String email;
  final String message;
  final bool emailTouched;

  bool get isEmailValid => isValidEmailReceiptAddress(email);

  String? get emailError {
    if (!emailTouched) {
      return null;
    }

    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'Email address is required';
    }

    if (!isEmailValid) {
      return 'Enter a valid email address';
    }

    return null;
  }

  bool get canSendReceipt => isEmailValid;

  PosEmailReceiptFormState copyWith({
    String? email,
    String? message,
    bool? emailTouched,
  }) {
    return PosEmailReceiptFormState(
      email: email ?? this.email,
      message: message ?? this.message,
      emailTouched: emailTouched ?? this.emailTouched,
    );
  }
}

class PosEmailReceiptFormNotifier extends StateNotifier<PosEmailReceiptFormState> {
  PosEmailReceiptFormNotifier() : super(const PosEmailReceiptFormState());

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      emailTouched: true,
    );
  }

  void setMessage(String value) {
    if (value.length > posEmailReceiptMessageMaxLength) {
      return;
    }

    state = state.copyWith(message: value);
  }

  void markEmailTouched() {
    if (!state.emailTouched) {
      state = state.copyWith(emailTouched: true);
    }
  }

  void clear() {
    state = const PosEmailReceiptFormState();
  }
}

final posEmailReceiptFormProvider =
    StateNotifierProvider<PosEmailReceiptFormNotifier, PosEmailReceiptFormState>(
  (ref) => PosEmailReceiptFormNotifier(),
);
