import 'add_product_wizard_state.dart';
import 'add_product_wizard_state_codec.dart';

/// Frontend-local Product Wizard draft. Not a backend Product row.
class ProductWizardDraft {
  final String localDraftId;
  final String productName;
  final String? productCode;
  final String productType;
  final String status;
  final int currentStep;
  final int? lastCompletedStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AddProductWizardState wizardState;

  const ProductWizardDraft({
    required this.localDraftId,
    required this.productName,
    this.productCode,
    required this.productType,
    this.status = 'DRAFT',
    required this.currentStep,
    this.lastCompletedStep,
    required this.createdAt,
    required this.updatedAt,
    required this.wizardState,
  });

  factory ProductWizardDraft.fromWizardState({
    required AddProductWizardState state,
    required String localDraftId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ProductWizardDraft(
      localDraftId: localDraftId,
      productName: state.productName.trim().isEmpty
          ? 'Untitled Product'
          : state.productName.trim(),
      productCode:
          state.internalCode.trim().isEmpty ? null : state.internalCode.trim(),
      productType: state.productStructure,
      status: 'DRAFT',
      currentStep: state.currentStep,
      lastCompletedStep: state.lastCompletedSetupStep,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      wizardState: state.copyWith(
        localDraftId: localDraftId,
        status: 'DRAFT',
        productId: state.productId,
        isDirty: false,
        isSavingDraft: false,
        isSubmitting: false,
        isLoadingOptions: false,
        clearPageError: true,
        fieldErrors: const {},
        // Options reloaded on resume — do not persist catalog snapshot.
        createOptions: null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localDraftId': localDraftId,
      'productName': productName,
      'productCode': productCode,
      'productType': productType,
      'status': status,
      'currentStep': currentStep,
      'lastCompletedStep': lastCompletedStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'wizardState': AddProductWizardStateCodec.toJson(wizardState),
    };
  }

  factory ProductWizardDraft.fromJson(Map<String, dynamic> json) {
    final wizard = AddProductWizardStateCodec.fromJson(
      Map<String, dynamic>.from(json['wizardState'] as Map? ?? {}),
    );
    return ProductWizardDraft(
      localDraftId: json['localDraftId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? wizard.productName,
      productCode: json['productCode']?.toString(),
      productType: json['productType']?.toString() ?? wizard.productStructure,
      status: json['status']?.toString() ?? 'DRAFT',
      currentStep: (json['currentStep'] as num?)?.toInt() ?? wizard.currentStep,
      lastCompletedStep: (json['lastCompletedStep'] as num?)?.toInt() ??
          wizard.lastCompletedSetupStep,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      wizardState: wizard.copyWith(
        localDraftId: json['localDraftId']?.toString(),
        status: 'DRAFT',
      ),
    );
  }

  ProductWizardDraft copyWith({
    String? productName,
    String? productCode,
    String? productType,
    String? status,
    int? currentStep,
    int? lastCompletedStep,
    DateTime? updatedAt,
    AddProductWizardState? wizardState,
  }) {
    return ProductWizardDraft(
      localDraftId: localDraftId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      productType: productType ?? this.productType,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      lastCompletedStep: lastCompletedStep ?? this.lastCompletedStep,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wizardState: wizardState ?? this.wizardState,
    );
  }
}
