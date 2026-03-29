/// حالات طلب الدفع (Payment Request Status)
enum PaymentRequestStatus {
  active('ACTIVE'),
  fulfilled('FULFILLED'),
  expired('EXPIRED'),
  cancelled('CANCELLED');

  const PaymentRequestStatus(this.value);

  final String value;

  /// تحويل من string إلى enum
  static PaymentRequestStatus fromString(String value) {
    return PaymentRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentRequestStatus.active,
    );
  }

  /// هل الطلب نشط؟
  bool get isActive => this == PaymentRequestStatus.active;

  /// هل الطلب مكتمل؟
  bool get isFulfilled => this == PaymentRequestStatus.fulfilled;

  /// هل الطلب منتهي الصلاحية؟
  bool get isExpired => this == PaymentRequestStatus.expired;

  /// هل الطلب ملغى؟
  bool get isCancelled => this == PaymentRequestStatus.cancelled;

  /// هل الطلب يمكن استخدامه؟
  bool get isUsable => isActive;
}
